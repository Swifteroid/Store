import CoreData
import Foundation

/// Batch is a load / save / delete operation, occasionally search, it is responsible for all Core Data handling and populating models
/// and objects. It's typically one time thing and disposed immediately, it shouldn't be used to store models as they get modified. 

open class Batch<ModelType:ModelProtocol>: BatchProtocol
{
    public typealias Model = ModelType

    public required init(models: [Model]? = nil, remodels: [Model]? = nil) {
        self.models = models ?? []
        self.remodels = remodels ?? []
    }

    // MARK: -

    open var coordinator: Coordinator?

    /// Explicitly defined or resulted set of models, which may change after each operation, thus, two identical operations invoked 
    /// consecutively may product different result, because their input may differ.   

    open var models: [Model]

    /// Models to use during loading instead of creating new ones. They are slightly different from assigned ones in a way that reusable
    /// can be either used or not, depending on whether request returns associated objects, whether models imply that they all should 
    /// be returned and populated.

    open var remodels: [Model]

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

    /// Depending on whether models are provided / empty or not load operation either pulls and updates these exact models or uses standard
    /// fetch operation. Therefore, provided fetch configuration will only be used when models are not explicitly specified. Providing
    /// remodels will result in a full fetch and will also reuse available models instead of creating new ones where possible.

    @discardableResult open func load(configuration: Model.Configuration? = nil) throws -> Self {
        let context: Context = Context(coordinator: (self.coordinator ?? Coordinator.default), concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        let models: [Model] = self.models
        var loaded: [Model] = []
        var failed: [Model] = []

        if models.isEmpty {
            let request: NSFetchRequest<Object> = self.prepare(request: NSFetchRequest(), configuration: configuration)
            var remodels: [Object.Id: Model] = [:]

            for model in self.remodels {
                if let id: Object.Id = model.id {
                    remodels[id] = model
                }
            }

            for object: Object in try context.fetch(request) {
                if let model: Model = remodels[object.objectID] {
                    self.update(model: model, with: object, configuration: configuration)
                    loaded.append(model)
                } else {
                    let model: Model = self.construct(with: object, configuration: configuration)
                    model.id = object.objectID
                    loaded.append(model)
                }
            }
        } else {
            for model in models {
                if let object: Object = try context.existingObject(with: model) {
                    loaded.append(self.update(model: model, with: object, configuration: configuration))
                } else {
                    failed.append(model)
                }
            }
        }

        self.models = loaded

        if !failed.isEmpty {
            throw Error.load(failed)
        }

        return self
    }

    @discardableResult open func prepare<Result>(request: NSFetchRequest<Result>, configuration: Model.Configuration? = nil) -> NSFetchRequest<Result> {
        request.entity = (self.coordinator ?? Coordinator.default)?.schema.entity(for: self)

        if let configuration: FetchConfiguration = (configuration as? ModelFetchConfigurationProtocol)?.fetch {
            if let limit: Int = configuration.limit { request.fetchLimit = limit }
            if let offset: Int = configuration.offset { request.fetchOffset = offset }
            if let sort: [NSSortDescriptor] = configuration.sort { request.sortDescriptors = sort }
        }

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
            } else if let entity: Entity = coordinator.schema.entity(for: model) {
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
            model.id = object.objectID
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

extension Batch
{
    public enum Error: Swift.Error
    {
        case load([Model])
    }
}