import CoreData

open class ModelSet<Element:Model, Configuration>
{
    open var store: Store?

    open var models: [Element] = []

    public init(models: [Element]) {
        self.models = models
    }

    // MARK: -

    @discardableResult open func load(configuration: Configuration? = nil) throws -> Self {
        typealias Models = (identified: [String: Element], loaded: [Element])

        // Todo: try! or try?
        // Todo: request will pull everything, must limit this to ids only, if have any.
        // Todo: differentiate between new and existing model.

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
            if let model: Element = models.identified[String(objectId: object.objectID)] {
                models.loaded.append(self.update(model: model, with: object, configuration: configuration))
            } else {
                models.loaded.append(self.construct(with: object, configuration: configuration))
            }
        }

        self.models = models.loaded
        return self
    }

    @discardableResult open func prepare<Result>(request: NSFetchRequest<Result>, configuration: Configuration? = nil) -> NSFetchRequest<Result> {
        let store: Store = (self.store ?? Store.default)
        let entity: NSEntityDescription? = store.schema.entity(for: self)

        request.entity = entity

        return request
    }

    @discardableResult open func construct(with object: NSManagedObject, configuration: Configuration? = nil) -> Element {
        abort()
    }

    @discardableResult open func update(model: Element, with object: NSManagedObject, configuration: Configuration? = nil) -> Element {
        model.id = String(objectId: object.objectID)
        return model
    }

    // MARK: -

    @discardableResult open func save(configuration: Configuration? = nil) throws -> Self {
        guard !self.models.isEmpty else {
            return self
        }

        let store: Store = (self.store ?? Store.default)
        let coordinator: NSPersistentStoreCoordinator = store.coordinator
        let context: NSManagedObjectContext = NSManagedObjectContext(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)

        // Acquire objects for updating. 

        for model in self.models {
            if let object: NSManagedObject = try context.existingObject(with: model) {
                self.update(object: object, with: model, configuration: configuration)
            } else if let entity: NSEntityDescription = store.schema.entity(for: model) {
                self.update(object: NSManagedObject(entity: entity, insertInto: context), with: model, configuration: configuration)
            }

            // Todo: should collect models that weren't saved and later throw a corresponding error.

        }

        if context.hasChanges {
            try context.save()
        }

        return self
    }

    @discardableResult open func update(object: NSManagedObject, with model: Element, configuration: Configuration? = nil) -> NSManagedObject {
        return object
    }

    // MARK: -

    @discardableResult open func delete(configuration: Configuration? = nil) throws -> Self {
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

extension NSManagedObject
{
    open func setValues(_ keyedValues: [String: Any]) -> Self {
        self.setValuesForKeys(keyedValues)
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

    fileprivate func existingObject(with model: Model) throws -> NSManagedObject? {
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