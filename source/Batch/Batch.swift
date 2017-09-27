import CoreData
import Foundation

/// Batch is a load / save / delete operation, occasionally search, it is responsible for all Core Data handling and populating models
/// and objects. It's typically one time thing and disposed immediately, it shouldn't be used to store models as they get modified.
///
/// - todo: What about cache when saving / deleting models?

open class Batch<Model:ModelProtocol & Hashable, Configuration>: BatchProtocol
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

        let transaction: Transaction? = Transaction.current
        let context: Context = self.context ?? transaction?.context ?? CacheableContext(coordinator: self.coordinator ?? Coordinator.default, concurrency: .privateQueueConcurrencyType)
        var exists: Bool = true

        // If any model doesn't exist than we return false.

        context.performAndWait({
            for model in models {
                if (try? context.existingObject(with: model)) ?? nil == nil { // This is fucking priceless…
                    exists = false
                    return
                }
            }
        })

        return exists
    }

    // MARK: -

    open func construct(with object: Object, configuration: Configuration? = nil, cache: ModelCache? = nil, update: Bool? = nil) throws -> Model {
        if let model: Model = (Model.self as? Store.BatchConstructableModelProtocol.Type)?.init(id: object.objectID) as? Model {

            // This is very important that newly constructed and identified model is added to cache before updating, otherwise 
            // it may result in recursion when construction interdependent relationships.

            cache?.add(model: model)

            // By default the model will be updated, unless it's explicitly specified otherwise.

            return update == false ? model : try self.update(model: model, with: object, configuration: configuration)
        } else {
            throw Error.construct
        }
    }

    // MARK: -

    /// Depending on whether models are provided / empty or not load operation either pulls and updates these exact models or uses standard
    /// fetch operation. Therefore, provided fetch configuration will only be used when models are not explicitly specified. Providing
    /// remodels will result in a full fetch and will also reuse available models instead of creating new ones where possible.

    @discardableResult open func load(configuration: Configuration? = nil) throws -> Self {

        // Cache explicitly specified by the batch has higher priority over one specified in cacheable context.  

        let transaction: Transaction? = Transaction.current
        let context: Context = self.context ?? transaction?.context ?? CacheableContext(coordinator: (self.coordinator ?? Coordinator.default), concurrency: .privateQueueConcurrencyType, cache: self.cache)
        var error: Swift.Error?

        context.performAndWait({
            do {
                let cache: ModelCache? = self.cache ?? (context as? CacheableContext)?.cache

                let models: [Model] = self.models
                var loaded: [(Model, Object)] = []
                var failed: [Model] = []

                // It's worth mentioning that models retrieved from cache get updated – this behaviour is different when accessing relationships
                // and allows to avoid unnecessary updated.

                if models.isEmpty {
                    let request: Request = self.prepare(request: Request(), configuration: configuration)

                    for object: Object in try context.fetch(request) {
                        if let model: Model = cache?.model(with: object.objectID) {
                            loaded.append(model, object)
                        } else {
                            let model: Model = try self.construct(with: object, configuration: configuration, cache: cache, update: false)
                            loaded.append(model, object)
                            cache?.add(model: model)
                        }
                    }
                } else {

                    // It is essential to add loaded models to cache before they get updated, otherwise interrelated relationships may end
                    // up creating exact copies of these models.

                    cache?.add(models: models)

                    for model in models {
                        if let object: Object = try context.existingObject(with: model) {
                            loaded.append(model, object)
                            cache?.add(model: model)
                        } else {
                            failed.append(model)
                        }
                    }
                }

                // Actual model updating happens after they all get constructed, this is needed for interrelated one-to-many and many-to-many
                // relationships, when construction is disabled on sub-models – without this sub-models may end up not having relationships
                // constructed after their update. Complicated… // Todo: this is not efficient. Perhaps we should do this only if current
                // todo: configuration conforms to batch relationship configuration protocol and if cache is available.

                // Todo: uh… oh… mapping… try doing it with regular loops.

                self.models = try loaded.map({ try self.update(model: $0.0, with: $0.1, configuration: configuration) })

                if !failed.isEmpty {
                    throw Error.load(failed)
                }
            } catch let caught {
                error = caught
            }
        })

        if let error = error {
            throw error
        } else {
            return self
        }
    }

    @discardableResult open func update(model: Model, with object: Object, configuration: Configuration? = nil) throws -> Model {
        return model
    }

    open func prepare(request: Request, configuration: Configuration? = nil) -> Request {
        request.entity = (self.coordinator ?? Coordinator.default)?.schema.entity(for: self)

        if let configuration: Request.Configuration = (configuration as? BatchRequestConfiguration)?.request {
            if let limit: Int = configuration.limit { request.fetchLimit = limit }
            if let offset: Int = configuration.offset { request.fetchOffset = offset }
            if let sort: [NSSortDescriptor] = configuration.sort { request.sortDescriptors = sort }
            configuration.block?(request)
        }

        return request
    }

    // MARK: -

    @discardableResult open func save(configuration: Configuration? = nil) throws -> Self {
        let models: [Model] = self.models
        if models.isEmpty { return self }

        let transaction: Transaction? = Transaction.current
        let context: Context = self.context ?? transaction?.context ?? Context(coordinator: self.coordinator ?? Coordinator.default, concurrency: .privateQueueConcurrencyType)
        var error: Swift.Error?

        context.performAndWait({
            do {
                var saved: [Model: Object] = [:]
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
                        saved[model] = object
                    } else {
                        failed.append(model)
                    }
                }

                // Update ids of inserted models, this is done separately, because ids become available only after 
                // context gets saved. If we're inside a transaction, we tell that son of a bitch to identify our
                // models whenever it completes.

                if let transaction: Transaction = transaction {
                    transaction.save(models: saved)
                } else if context.hasChanges {
                    NotificationCenter.default.post(name: BatchNotification.willSaveContext, object: self, userInfo: [BatchNotification.Key.context: context])
                    try context.save()
                    for (model, object) in saved { model.id = object.objectID }
                }

                if !failed.isEmpty {
                    throw Error.save(failed)
                }
            } catch let caught {
                error = caught
            }
        })

        if let error = error {
            throw error
        } else {
            return self
        }
    }

    @discardableResult open func update(object: Object, with model: Model, configuration: Configuration? = nil) throws -> Object {
        return object
    }

    // MARK: -

    @discardableResult open func delete(configuration: Configuration? = nil) throws -> Self {
        let models: [Model] = self.models
        if models.isEmpty { return self }

        let context: Context = Context(coordinator: self.coordinator ?? Coordinator.default, concurrency: .privateQueueConcurrencyType)
        var error: Swift.Error?

        context.performAndWait({
            do {
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
            } catch let caught {
                error = caught
            }
        })

        if let error = error {
            throw error
        } else {
            return self
        }
    }
}

extension Batch
{

    /// - todo: Is this the way to do it?

    public enum Error: Swift.Error
    {
        case construct
        case load([Model])
        case save([Model])
    }
}