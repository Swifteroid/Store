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

        var objects: (inserted: [Object.Id: Object], deleted: [Object.Id: Object], updated: [Object.Id: Object]) = (inserted: [:], deleted: [:], updated: [:])

        for object in self.mode.contains(.insert) ? inserted : [] {
            if object.entity == entity { objects.inserted[object.objectID] = object }
        }

        for object in self.mode.contains(.delete) ? deleted : [] { if object.entity == entity { objects.deleted[object.objectID] = object } }
        for object in self.mode.contains(.update) ? updated : [] { if object.entity == entity { objects.updated[object.objectID] = object } }

        if objects.inserted.isEmpty && objects.deleted.isEmpty && objects.updated.isEmpty {
            return
        }

        var models: (identified: [String: Model], unidentified: [Model]) = (identified: [:], unidentified: [])
        let configuration: Batch.Configuration? = self.configuration as! Batch.Configuration?
        let batch: Batch = Batch(models: [])

        // Todo: This can be optimised further by not re-looping, using lazy model construction and checking
        // todo: if any models got actually changed.

        for model in self.models {
            if let id: String = model.id {
                models.identified[id] = model
            } else {
                models.unidentified.append(model)
            }
        }

        for (id, object) in objects.inserted {
            let model: Model = batch.construct(with: object, configuration: configuration) as! Model
            let id: String = String(id: id)
            model.id = id
            models.identified[id] = model
        }

        for (id, _) in objects.deleted {
            if let _: Model = models.identified.removeValue(forKey: String(id: id)) {
                // Something got changed…
            }
        }

        for (id, object) in objects.updated {
            if let model: Model = models.identified[String(id: id)] {
                batch.update(model: model as! Batch.Model, with: object, configuration: configuration)
            }
        }

        self.models = models.identified.values + models.unidentified

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