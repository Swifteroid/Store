import CoreData
import Foundation

open class Batch<ModelType:ModelProtocol>: BatchProtocol
{
    public typealias Model = ModelType

    open var coordinator: Coordinator?

    open var models: [Model] = []

    public required init(models: [Model]) {
        self.models = models
    }

    // MARK: -

    public func exist(models: [Model]? = nil) -> Bool {
        let models: [Model] = models ?? self.models
        if models.isEmpty { return false }

        let coordinator: Coordinator = (self.coordinator ?? Coordinator.default)
        let context: NSManagedObjectContext = NSManagedObjectContext(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)

        // If any model doesn't exist than we return false.

        for model in models {
            if (try? context.existingObject(with: model)) ?? nil == nil { // This is priceless…
                return false
            }
        }

        return true
    }

    @discardableResult open func load(configuration: Model.Configuration? = nil) throws -> Self {
        typealias Models = (identified: [String: Model], loaded: [Model])

        // Todo: request will pull everything, must limit this to ids only, if have any.

        let coordinator: Coordinator = (self.coordinator ?? Coordinator.default)
        let context: NSManagedObjectContext = NSManagedObjectContext(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        let request: NSFetchRequest<Object> = self.prepare(request: NSFetchRequest(), configuration: configuration)
        var models: Models = (identified: [:], loaded: [])

        for model in self.models {
            if let id: String = model.id {
                models.identified[id] = model
            }
        }

        for object: Object in try context.fetch(request) {
            if let model: Model = models.identified[String(objectId: object.objectID)] {
                models.loaded.append(self.update(model: model, with: object, configuration: configuration))
            } else {
                let model: Model = self.construct(with: object, configuration: configuration)
                model.id = String(objectId: object.objectID)
                models.loaded.append(model)
            }
        }

        self.models = models.loaded
        return self
    }

    @discardableResult open func prepare<Result>(request: NSFetchRequest<Result>, configuration: Model.Configuration? = nil) -> NSFetchRequest<Result> {
        let coordinator: Coordinator = (self.coordinator ?? Coordinator.default)
        let entity: NSEntityDescription? = coordinator.schema.entity(for: self)

        request.entity = entity

        return request
    }

    @discardableResult open func construct(with object: Object, configuration: Model.Configuration? = nil) -> Model {
        abort()
    }

    @discardableResult open func update(model: Model, with object: Object, configuration: Model.Configuration? = nil) -> Model {
        return model
    }

    // MARK: -

    @discardableResult open func save(configuration: Model.Configuration? = nil) throws -> Self {
        guard !self.models.isEmpty else {
            return self
        }

        let coordinator: Coordinator = (self.coordinator ?? Coordinator.default)
        let context: NSManagedObjectContext = NSManagedObjectContext(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        var models: [Object: Model] = [:]

        // Acquire objects for updating. 

        for model in self.models {
            if let object: Object = try context.existingObject(with: model) {
                self.update(object: object, with: model, configuration: configuration)
            } else if let entity: NSEntityDescription = coordinator.schema.entity(for: model) {
                let object: Object = Object(entity: entity, insertInto: context)
                self.update(object: object, with: model, configuration: configuration)
                models[object] = model
            }

            // Todo: should collect models that weren't saved and later throw a corresponding error.

        }

        if context.hasChanges {
            NotificationCenter.default.post(name: BatchNotification.willSaveContext, object: self, userInfo: [BatchNotification.Key.context: context])
            try context.save()
        }

        // Update ids of inserted models.

        for (object, model) in models {
            model.id = String(objectId: object.objectID)
        }

        return self
    }

    @discardableResult open func update(object: Object, with model: Model, configuration: Model.Configuration? = nil) -> Object {
        return object
    }

    // MARK: -

    @discardableResult open func delete(configuration: Model.Configuration? = nil) throws -> Self {
        guard !self.models.isEmpty else {
            return self
        }

        let coordinator: Coordinator = (self.coordinator ?? Coordinator.default)
        let context: NSManagedObjectContext = NSManagedObjectContext(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)

        for model in self.models {
            if let object: Object = try context.existingObject(with: model) {
                context.delete(object)
            }
        }

        if context.hasChanges {
            NotificationCenter.default.post(name: BatchNotification.willSaveContext, object: self, userInfo: [BatchNotification.Key.context: context])
            try context.save()
        }

        self.models = []
        return self
    }
}

// MARK: -

extension Object
{
    open func setValues(_ values: [String: Any]) -> Self {
        self.setValuesForKeys(values)
        return self
    }

    public func value(set value: Any?, for key: String) {
        self.setValue(value, forKey: key)
    }

    public func value<Value>(for key: String) -> Value {
        return self.value(forKey: key) as! Value
    }
}

// MARK: relationship

extension Object
{

    /*
    Returns related models using model construction method in batch derived from specified batchable protocol.
    */
    open func relationship<T:BatchableProtocol>(for name: String) -> [T] {
        let batch: Batch<T> = T.Batch(models: []) as! Batch<T>
        var models: [T] = []

        for object in self.mutableSetValue(forKey: name).allObjects as! [Object] {
            let model: T = batch.construct(with: object)
            model.id = String(objectId: object.objectID)
            models.append(model)
        }

        return models
    }

    /*
    Sets new relationship objects replacing all existing ones.
    */
    open func relationship(set objects: [Object], for name: String) {
        let set: NSMutableSet = self.mutableSetValue(forKey: name)
        set.removeAllObjects()
        set.addObjects(from: objects)
    }

    /*
    Sets new relationship models.
    */
    open func relationship<Model:ModelProtocol>(set models: [Model], for name: String) throws {
        guard let context: NSManagedObjectContext = self.managedObjectContext else { throw RelationshipError.noContext }
        var objects: [Object] = []

        for model in models {
            if let object: Object = try context.existingObject(with: model) {
                objects.append(object)
            } else {
                throw RelationshipError.noObject
            }
        }

        self.relationship(set: objects, for: name)
    }
}

extension Object
{
    public enum RelationshipError: Error
    {
        /*
        Managed object upon which a relationship is being updated has no context making it impossible to retrieve model
        managed objects.
        */
        case noContext

        /*
        Cannot retrieve model's managed object, it's probably not saved or got deleted. 
        */
        case noObject
    }
}

// MARK: -

extension NSManagedObjectContext
{
    public convenience init(coordinator: NSPersistentStoreCoordinator, concurrency: NSManagedObjectContextConcurrencyType) {
        self.init(concurrencyType: concurrency)
        self.persistentStoreCoordinator = coordinator
    }

    fileprivate func existingObject<Model:ModelProtocol>(with model: Model) throws -> Object? {
        if let modelId: String = model.id, let url: URL = URL(string: modelId), let objectId: NSManagedObjectID = self.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) {
            return try self.existingObject(with: objectId)
        } else {
            return nil
        }
    }
}

// MARK: -

extension String
{
    fileprivate init(objectId: NSManagedObjectID) {
        self = objectId.uriRepresentation().absoluteString
    }
}