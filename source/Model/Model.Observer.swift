import CoreData
import Foundation

public protocol ModelObserverProtocol: class
{
    associatedtype Model: BatchableProtocol
    associatedtype Batch: BatchProtocol
    associatedtype Configuration: ModelConfigurationProtocol

    /// Invoked when the default notification center posts `NSManagedObjectContextDidSave` notification with provided
    /// context and changed objects.

    func update(context: Context, inserted: Set<Object>, deleted: Set<Object>, updated: Set<Object>)
}

/*
Model observer provides a way of smart global model change tracking by listening for `NSManagedObjectContext` change notifications and selectively 
merging those changes into observer.
*/
open class ModelObserver<ModelType:BatchableProtocol>: ModelObserverProtocol
{
    public typealias Model = ModelType
    public typealias Batch = Model.Batch
    public typealias Configuration = Model.Configuration

    /// - parameter models: Providing `nil` models will result in all models being loaded in accordance with specified configuration.

    public init(mode: ModelObserverMode? = nil, models: [Model]? = nil, configuration: Configuration? = nil) {
        self.mode = mode ?? .all
        self.configuration = configuration

        if let models: [Model] = models {
            self.models = models
        } else {
            self.models = try! Batch(models: []).load(configuration: self.configuration as! Batch.Configuration?).models as! [Model]
        }

        self.observer = NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextDidSave, object: nil, queue: OperationQueue.current, using: { [weak self] in self?.handleContextNotification($0) })
    }

    deinit {
        if let observer: Any = self.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: -

    private var observer: Any?

    open var mode: ModelObserverMode

    open var models: [Model]

    open var configuration: Configuration?

    // MARK: -

    open func update(context: Context, inserted: Set<Object>, deleted: Set<Object>, updated: Set<Object>) {
        guard let entity: Entity = (context.coordinator ?? Coordinator.default)?.schema.entity(for: Model.self) else { return }

        // First we must figure out if any of saved changed relate to our observation. 

        var insertedById: [Object.Id: Object] = [:]
        var deletedById: [Object.Id: Object] = [:]
        var updatedById: [Object.Id: Object] = [:]

        for object in self.mode.contains(.insert) ? inserted : [] { if object.entity == entity { insertedById[object.objectID] = object } }
        for object in self.mode.contains(.delete) ? deleted : [] { if object.entity == entity { deletedById[object.objectID] = object } }
        for object in self.mode.contains(.update) ? updated : [] { if object.entity == entity { updatedById[object.objectID] = object } }

        if insertedById.isEmpty && deletedById.isEmpty && updatedById.isEmpty {
            return
        }

        let configuration: Batch.Configuration? = self.configuration as! Batch.Configuration?
        let batch: Batch = Batch(models: [])
        var models: [Model] = self.models

        // In order to preserve the order of models we must take care of properly updating them, deletions
        // should also be made from high to low index.

        var modelIndexes: [String: Int] = [:]
        var deletionIndexes: [Int] = []
        var objectsByModel: [Model: Object?] = [:]

        // Todo: This can be optimised further by not re-looping, using lazy model construction and checking
        // todo: if any models got actually changed.

        for i in 0 ..< models.count {
            if let id: String = models[i].id {
                modelIndexes[id] = i
            }
        }

        for (id, object) in insertedById {
            let model: Model = batch.construct(with: object, configuration: configuration) as! Model
            let id: String = String(id: id)

            objectsByModel[model] = object
            model.id = id

            models.append(model)
        }

        for (id, object) in updatedById {
            if let index: Int = modelIndexes[String(id: id)] {
                batch.update(model: models[index] as! Batch.Model, with: object, configuration: configuration)
                objectsByModel[models[index]] = object
            }
        }

        for (id, _) in deletedById {
            if let index: Int = modelIndexes[String(id: id)] {
                deletionIndexes.append(index)
            }
        }

        // Remove deleted models based on descending collected deletion indexes.

        for index in deletionIndexes.sorted(by: { $0 > $1 }) {
            models.remove(at: index)
        }

        // Serious black magic here… typically we want to ensure that updates happen as if they were real fetches, hence
        // we must make sure that fetch configuration applies to models.

        if !insertedById.isEmpty, let configuration: FetchConfiguration = (configuration as? ModelFetchConfigurationProtocol)?.fetch {
            if let sort: [NSSortDescriptor] = configuration.sort, !sort.isEmpty {
                models.sort(by: {
                    if objectsByModel[$0] == nil { objectsByModel[$0] = try? context.existingObject(with: $0) }
                    if objectsByModel[$1] == nil { objectsByModel[$1] = try? context.existingObject(with: $1) }

                    let lhs: Object! = objectsByModel[$0] ?? nil
                    let rhs: Object! = objectsByModel[$1] ?? nil

                    if lhs == nil && rhs == nil {
                        return false
                    } else if lhs == nil && rhs != nil {
                        return true
                    } else if lhs != nil && rhs == nil {
                        return false
                    }

                    for sort in sort {
                        switch sort.compare(lhs, to: rhs) {
                            case .orderedAscending: return true
                            case .orderedDescending: return false
                            case .orderedSame: continue
                        }
                    }

                    return false
                })
            }

            // Note, that offset fetch configuration doesn't apply here, because it's not clear how it would
            // work. Suggestions are welcome! 

            if let limit: Int = configuration.limit, models.count > limit {
                models = Array(models.prefix(limit))
            }
        }

        self.models = models

        NotificationCenter.default.post(name: ModelObserverNotification.didUpdate, object: self)
    }

    // MARK: -

    private func handleContextNotification(_ notification: Notification) {
        if let context: Context = notification.object as? Context {
            self.update(
                context: context,
                inserted: notification.userInfo?[NSInsertedObjectsKey] as? Set<Object> ?? Set(),
                deleted: notification.userInfo?[NSDeletedObjectsKey] as? Set<Object> ?? Set(),
                updated: notification.userInfo?[NSUpdatedObjectsKey] as? Set<Object> ?? Set()
            )
        }
    }
}

// MARK: -

public struct ModelObserverMode: OptionSet
{
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public let rawValue: Int

    // MARK: -

    public static let insert: ModelObserverMode = ModelObserverMode(rawValue: 1 << 0)
    public static let delete: ModelObserverMode = ModelObserverMode(rawValue: 1 << 1)
    public static let update: ModelObserverMode = ModelObserverMode(rawValue: 1 << 2)
    public static let all: ModelObserverMode = [.insert, .update, .delete]
}

// MARK: -

public struct ModelObserverNotification
{
    public static let didUpdate: Notification.Name = Notification.Name("ModelObserverDidUpdateNotification")
}