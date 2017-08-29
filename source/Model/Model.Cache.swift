/// Provides means for caching already loaded modes. Needed mostly for interrelated model load recursion handling, but can be used
/// simply to reuse already existing models during the load, like `ModelObserver<…>` does.

public protocol ModelCache: class
{

    func model<Model:Store.Model>(with id: Object.Id) -> Model?

    /// Adds model to cache.

    func add<Model:Store.Model>(model: Model)

    func add<Model:Store.Model>(models: [Model])

    func remove<Model:Store.Model>(model: Model)

    func remove<Model:Store.Model>(models: [Model])
}

extension ModelCache
{
    public func add<Model:Store.Model>(models: [Model]) {
        for model in models { self.add(model: model) }
    }

    public func remove<Model:Store.Model>(models: [Model]) {
        for model in models { self.remove(model: model) }
    }
}

// MARK: -

open class ArrayModelCache: ModelCache
{
    public init(_ values: [Any]? = nil) {
        self.values = values ?? []
    }

    open var values: [Any]

    open func model<Model:Store.Model>(with id: Object.Id) -> Model? {
        return self.values.first(where: { ($0 as? Model)?.id == id }) as? Model
    }

    open func add<Model:Store.Model>(model: Model) {
        self.values.append(model)
    }

    open func remove<Model:Store.Model>(model: Model) {
        self.values = self.values.filter({ $0 as? Model !== model })
    }
}

open class DictionaryModelCache: ModelCache
{
    public init(_ values: [Object.Id: Any]? = nil) {
        self.values = values ?? [:]
    }

    open var values: [Object.Id: Any]

    open func model<Model:Store.Model>(with id: Object.Id) -> Model? {
        return self.values[id] as? Model
    }

    open func add<Model:Store.Model>(model: Model) {
        if let id: Object.Id = model.id { self.values[id] = model }
    }

    open func remove<Model:Store.Model>(model: Model) {
        if let id: Object.Id = model.id { self.values.removeValue(forKey: id) }
    }
}