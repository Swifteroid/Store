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
            self.update()
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

    open var configuration: Configuration?

    open var models: [Model] {
        get {
            return self.observed ?? self.assigned ?? []
        }
        set {
            self.assigned = newValue.isEmpty ? nil : newValue
            self.observed = nil
        }
    }

    /// Explicitly assigned models for observing.

    private var assigned: [Model]?

    /// Models discovered during observing.

    private var observed: [Model]?

    open var remodels: [Model] = []

    // MARK: -

    open func update() {
        let batch: Batch = Batch(models: (self.assigned as! [Batch.Model]?), remodels: (self.remodels + (self.observed ?? []) as! [Batch.Model]))
        try! batch.load(configuration: self.configuration as! Batch.Configuration?)

        self.observed = (batch.models as! [Model])
        NotificationCenter.default.post(name: ModelObserverNotification.didUpdate, object: self)
    }

    open func update(context: Context, inserted: Set<Object>, deleted: Set<Object>, updated: Set<Object>) {
        guard let entity: Entity = (context.coordinator ?? Coordinator.default)?.schema.entity(for: Model.self) else { return }

        // First we must figure out if any of saved changed relate to our observation. 

        var insertedById: [Object.Id: Object] = [:]
        var deletedById: [Object.Id: Object] = [:]
        var updatedById: [Object.Id: Object] = [:]

        for object in self.mode.contains(.insert) ? inserted : [] { if object.entity == entity { insertedById[object.objectID] = object } }
        for object in self.mode.contains(.delete) ? deleted : [] { if object.entity == entity { deletedById[object.objectID] = object } }
        for object in self.mode.contains(.update) ? updated : [] { if object.entity == entity { updatedById[object.objectID] = object } }

        // If there's no changes we can stop here, otherwise, if there's no explicitly assigned models we should use standard
        // update to do a proper fetch.

        if insertedById.isEmpty && deletedById.isEmpty && updatedById.isEmpty {
            return
        } else if self.assigned == nil {
            return self.update()
        }

        let configuration: Batch.Configuration? = self.configuration as! Batch.Configuration?
        let batch: Batch = Batch(models: [])
        var observed: [Model] = self.models
        var updated: Bool = !insertedById.isEmpty

        // In order to preserve the order of models we must take care of properly updating them, deletions
        // should also be made from high to low index.

        var modelIndexes: [Object.Id: Int] = [:]
        var deletionIndexes: [Int] = []
        var objectsByModel: [Model: Object?] = [:]

        for i in 0 ..< observed.count {
            if let id: Object.Id = observed[i].id {
                modelIndexes[id] = i
            }
        }

        for (id, object) in insertedById {
            let model: Model = batch.construct(with: object, configuration: configuration) as! Model

            objectsByModel[model] = object
            model.id = id

            observed.append(model)
        }

        for (id, object) in updatedById {
            if let index: Int = modelIndexes[id] {
                batch.update(model: observed[index] as! Batch.Model, with: object, configuration: configuration)
                objectsByModel[observed[index]] = object
                updated = true
            }
        }

        for (id, _) in deletedById {
            if let index: Int = modelIndexes[id] {
                deletionIndexes.append(index)
                updated = true
            }
        }

        // Remove deleted models based on descending collected deletion indexes.

        for index in deletionIndexes.sorted(by: { $0 > $1 }) {
            observed.remove(at: index)
        }

        // Serious black magic here… typically we want to ensure that updates happen as if they were real fetches, therefore, we must 
        // make sure that fetch configuration applies to models. This is still a shady area, offset configuration doesn't get applied
        // here, because it's not clear how it would work. Suggestions are welcome! 

        if !insertedById.isEmpty, let configuration: FetchConfiguration = (configuration as? ModelFetchConfigurationProtocol)?.fetch {
            if let sort: [NSSortDescriptor] = configuration.sort, !sort.isEmpty {
                observed.sort(by: {
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

            if let limit: Int = configuration.limit, observed.count > limit {
                observed = Array(observed.prefix(limit))
            }
        }

        self.observed = observed

        if updated {
            NotificationCenter.default.post(name: ModelObserverNotification.didUpdate, object: self)
        }
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