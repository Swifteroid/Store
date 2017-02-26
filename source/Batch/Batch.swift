import CoreData
import Foundation

open class Batch<ModelType:ModelProtocol>: BatchProtocol where ModelType.Key.Configuration == ModelType.Configuration
{
    public typealias Model = ModelType

    open var store: Store?

    open var models: [Model] = []

    public required init(models: [Model]) {
        self.models = models
    }

    // MARK: -

    @discardableResult open func load(configuration: Model.Configuration? = nil) throws -> Self {
        typealias Models = (identified: [String: Model], loaded: [Model])

        // Todo: try! or try?
        // Todo: request will pull everything, must limit this to ids only, if have any.

        let store: Store = (self.store ?? Store.default)
        let coordinator: NSPersistentStoreCoordinator = store.coordinator
        let context: NSManagedObjectContext = NSManagedObjectContext(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        let request: NSFetchRequest<NSManagedObject> = self.prepare(request: NSFetchRequest(), configuration: configuration)
        var models: Models = (identified: [:], loaded: [])

        for model in self.models {
            if let id: String = model.id {
                models.identified[id] = model
            }
        }

        for object: NSManagedObject in try context.fetch(request) {
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
        let store: Store = (self.store ?? Store.default)
        let entity: NSEntityDescription? = store.schema.entity(for: self)

        request.entity = entity

        return request
    }

    @discardableResult open func construct(with object: NSManagedObject, configuration: Model.Configuration? = nil) -> Model {
        abort()
    }

    @discardableResult open func update(model: Model, with object: NSManagedObject, configuration: Model.Configuration? = nil) -> Model {
        for key in Model.Key.for(configuration: configuration) {
            model[key] = object.value(forKey: key.rawValue)
        }

        return model
    }

    // MARK: -

    @discardableResult open func save(configuration: Model.Configuration? = nil) throws -> Self {
        guard !self.models.isEmpty else {
            return self
        }

        let store: Store = (self.store ?? Store.default)
        let coordinator: NSPersistentStoreCoordinator = store.coordinator
        let context: NSManagedObjectContext = NSManagedObjectContext(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        var models: [NSManagedObject: Model] = [:]

        // Acquire objects for updating. 

        for model in self.models {
            if let object: NSManagedObject = try context.existingObject(with: model) {
                self.update(object: object, with: model, configuration: configuration)
            } else if let entity: NSEntityDescription = store.schema.entity(for: model) {
                let object: NSManagedObject = NSManagedObject(entity: entity, insertInto: context)
                self.update(object: object, with: model, configuration: configuration)
                models[object] = model
            }

            // Todo: should collect models that weren't saved and later throw a corresponding error.

        }

        if context.hasChanges {
            try context.save()
        }

        // Update ids of inserted models.

        for (object, model) in models {
            model.id = String(objectId: object.objectID)
        }

        return self
    }

    @discardableResult open func update(object: NSManagedObject, with model: Model, configuration: Model.Configuration? = nil) -> NSManagedObject {
        for key in Model.Key.for(configuration: configuration) {
            object.setValue(model[key], forKey: key.rawValue)
        }

        return object
    }

    // MARK: -

    @discardableResult open func delete(configuration: Model.Configuration? = nil) throws -> Self {
        guard !self.models.isEmpty else {
            return self
        }

        let store: Store = (self.store ?? Store.default)
        let coordinator: NSPersistentStoreCoordinator = store.coordinator
        let context: NSManagedObjectContext = NSManagedObjectContext(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)

        for model in self.models {
            if let object: NSManagedObject = try context.existingObject(with: model) {
                context.delete(object)
            }
        }

        if context.hasChanges {
            try context.save()
        }

        self.models = []
        return self
    }
}

// MARK: -

public protocol BatchableProtocol: ModelProtocol
{
    associatedtype Batch: BatchProtocol
}

extension BatchableProtocol
{
    @discardableResult public func load(configuration: Batch.Model.Configuration? = nil) throws -> Self {
        try Batch(models: [self as! Batch.Model]).load(configuration: configuration)
        return self
    }

    @discardableResult public func save(configuration: Batch.Model.Configuration? = nil) throws -> Self {
        try Batch(models: [self as! Batch.Model]).save(configuration: configuration)
        return self
    }

    @discardableResult public func delete(configuration: Batch.Model.Configuration? = nil) throws -> Self {
        try Batch(models: [self as! Batch.Model]).delete(configuration: configuration)
        return self
    }
}

// MARK: -

extension NSManagedObject
{
    open func setValues(_ values: [String: Any]) -> Self {
        self.setValuesForKeys(values)
        return self
    }
}

// MARK: -

extension NSManagedObjectContext
{
    fileprivate convenience init(coordinator: NSPersistentStoreCoordinator, concurrency: NSManagedObjectContextConcurrencyType) {
        self.init(concurrencyType: concurrency)
        self.persistentStoreCoordinator = coordinator
    }

    fileprivate func existingObject<Model:ModelProtocol>(with model: Model) throws -> NSManagedObject? {
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