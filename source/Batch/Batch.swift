import CoreData
import Foundation

open class Batch<ModelType:ModelProtocol>: BatchProtocol
{
    public typealias Model = ModelType

    public init() {
    }

    public required init(models: [Model]) {
        self.models = models
    }

    // MARK: -

    open var coordinator: Coordinator?

    open var models: [Model] = []

    // MARK: -

    public func exist(models: [Model]? = nil) -> Bool {
        let models: [Model] = models ?? self.models
        if models.isEmpty { return false }

        let coordinator: Coordinator = (self.coordinator ?? Coordinator.default)
        let context: Context = Context(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)

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
        let context: Context = Context(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        let request: NSFetchRequest<Object> = self.prepare(request: NSFetchRequest(), configuration: configuration)
        var models: Models = (identified: [:], loaded: [])

        for model in self.models {
            if let id: String = model.id {
                models.identified[id] = model
            }
        }

        for object: Object in try context.fetch(request) {
            if let model: Model = models.identified[String(id: object.objectID)] {
                models.loaded.append(self.update(model: model, with: object, configuration: configuration))
            } else {
                let model: Model = self.construct(with: object, configuration: configuration)
                model.id = String(id: object.objectID)
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

        // Ideally this should be done in extension, but there seem to be no way to trick around the dynamic dispatch
        // on generic type. Todo: possible?

        if let InitialisableModel = Model.self as? InitialisableProtocol.Type {
            return self.update(model: InitialisableModel.init() as! Model, with: object, configuration: configuration)
        } else {
            abort()
        }
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
        let context: Context = Context(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
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
            model.id = String(id: object.objectID)
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
        let context: Context = Context(coordinator: coordinator, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)

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