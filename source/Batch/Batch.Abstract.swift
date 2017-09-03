import CoreData
import Foundation

/// Batch is a load / save / delete operation, occasionally search, it is responsible for all Core Data handling and populating models
/// and objects. It's typically one time thing and disposed immediately, it shouldn't be used to store models as they get modified.
///
/// - todo: What about cache when saving / deleting models?

open class AbstractBatch<Model:Store.Model, Configuration>: Batch
{
    public required init(coordinator: Coordinator? = nil, context: Context? = nil, cache: ModelCache? = nil, models: [Model]? = nil) {
        self.coordinator = coordinator
        self.context = context
        self.cache = cache
        self.models = models ?? []
    }

    // MARK: -

    open var coordinator: Coordinator?

    open var context: Context?

    open var cache: ModelCache?

    /// Explicitly defined or resulted set of models, which may change after each operation, thus, two identical operations invoked 
    /// consecutively may product different result, because their input may differ.

    open var models: [Model]

    // MARK: -

    public func exist(models: [Model]? = nil) -> Bool {
        let models: [Model] = models ?? self.models
        if models.isEmpty { return false }

        let context: Context = self.context ?? CacheableContext(coordinator: self.coordinator ?? Coordinator.default, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)

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

    @discardableResult open func load(configuration: Configuration? = nil) throws -> Self {

        // Cache explicitly specified by the batch has higher priority over one specified in cacheable context.  

        let context: Context = self.context ?? CacheableContext(coordinator: (self.coordinator ?? Coordinator.default), concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType, cache: self.cache)
        let cache: ModelCache? = self.cache ?? (context as? CacheableContext)?.cache
        let models: [Model] = self.models
        var loaded: [Model] = []
        var failed: [Model] = []

        // It's worth mentioning that models retrieved from cache get updated – this behaviour is different when accessing relationships
        // and allows to avoid unnecessary updated.

        if models.isEmpty {
            let request: Request = self.prepare(request: Request(), configuration: configuration)

            for object: Object in try context.fetch(request) {
                if let model: Model = cache?.model(with: object.objectID) {
                    loaded.append(try self.update(model: model, with: object, configuration: configuration))
                } else {
                    let model: Model = try self.construct(with: object, configuration: configuration, cache: cache)
                    loaded.append(model)
                    cache?.add(model: model)
                }
            }
        } else {

            // It is essential to add loaded models to cache before they get updated, otherwise interrelated relationships may end
            // up creating exact copies of these models.

            cache?.add(models: models)

            for model in models {
                if let object: Object = try context.existingObject(with: model) {
                    try self.update(model: model, with: object, configuration: configuration)
                    loaded.append(model)
                    cache?.add(model: model)
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

    @discardableResult open func prepare<Result>(request: NSFetchRequest<Result>, configuration: Configuration? = nil) -> NSFetchRequest<Result> {
        request.entity = (self.coordinator ?? Coordinator.default)?.schema.entity(for: self)

        if let configuration: Request.Configuration = (configuration as? BatchRequestConfiguration)?.request {
            if let limit: Int = configuration.limit { request.fetchLimit = limit }
            if let offset: Int = configuration.offset { request.fetchOffset = offset }
            if let sort: [NSSortDescriptor] = configuration.sort { request.sortDescriptors = sort }
        }

        return request
    }

    open func construct(with object: Object, configuration: Configuration? = nil, cache: ModelCache? = nil) throws -> Model {
        if let model: Model = (Model.self as? BatchConstructableModel.Type)?.init(id: object.objectID) as? Model {

            // This is very important that newly constructed and identified model is added to cache before updating, otherwise 
            // it may result in recursion when construction interdependent relationships.

            cache?.add(model: model)

            return try self.update(model: model, with: object, configuration: configuration)
        } else {
            throw Error.construct
        }
    }

    @discardableResult open func update(model: Model, with object: Object, configuration: Configuration? = nil) throws -> Model {
        return model
    }

    // MARK: -

    @discardableResult open func save(configuration: Configuration? = nil) throws -> Self {
        let models: [Model] = self.models
        if models.isEmpty { return self }

        let context: Context = self.context ?? Context(coordinator: self.coordinator ?? Coordinator.default, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        var saved: [Object: Model] = [:]
        var failed: [Model] = []

        // YO!!! I know you'll want to take entity retrieval out of the loop… FUCK YOU!!! AND DON'T!!! Reasons
        // are simple – model entity is worked out based on the model class name, while they all can ba children
        // of the same common class, their entities might differ. Though, there's one in a million chance…

        for model in models {
            if let object: Object = try context.existingObject(with: model) {
                try self.update(object: object, with: model, configuration: configuration)
            } else if let entity: Entity = context.coordinator?.schema.entity(for: model) {
                let object: Object = Object(entity: entity, insertInto: context)
                try self.update(object: object, with: model, configuration: configuration)
                saved[object] = model
            } else {
                failed.append(model)
            }
        }

        if context.hasChanges {
            NotificationCenter.default.post(name: BatchNotification.willSaveContext, object: self, userInfo: [BatchNotification.Key.context: context])
            try context.save()
        }

        // Update ids of inserted models, this is done separately, because ids become available 
        // only after context gets saved.

        for (object, model) in saved {
            model.id = object.objectID
        }

        if !failed.isEmpty {
            throw Error.save(failed)
        }

        return self
    }

    @discardableResult open func update(object: Object, with model: Model, configuration: Configuration? = nil) throws -> Object {
        return object
    }

    // MARK: -

    @discardableResult open func delete(configuration: Configuration? = nil) throws -> Self {
        let models: [Model] = self.models
        if models.isEmpty { return self }

        let context: Context = Context(coordinator: self.coordinator ?? Coordinator.default, concurrency: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)

        for model in models {
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

extension AbstractBatch
{

    /// - todo: Is this the way to do it?

    public enum Error: Swift.Error
    {
        case construct
        case load([Model])
        case save([Model])
    }
}