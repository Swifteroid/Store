/// Provides means for caching already loaded modes. Needed mostly for interrelated model load recursion handling, but can be used
/// simply to reuse already existing models during the load, like `ModelObserver<…>` does.

public protocol ModelCache: AnyObject {

    func model<Model: ModelProtocol>(with id: Object.Id) -> Model?

    /// Adds model to cache.

    func add<Model: ModelProtocol>(model: Model)

    func add<Model: ModelProtocol>(models: [Model])

    func remove<Model: ModelProtocol>(model: Model)

    func remove<Model: ModelProtocol>(models: [Model])
}

extension ModelCache {
    public func add<Model: ModelProtocol>(models: [Model]) {
        for model in models { self.add(model: model) }
    }

    public func remove<Model: ModelProtocol>(models: [Model]) {
        for model in models { self.remove(model: model) }
    }
}

// MARK: -

open class ArrayModelCache: ModelCache {
    public init(_ values: [ModelProtocol]? = nil) {
        self.values = values ?? []
    }

    open var values: [ModelProtocol]

    open func model<Model: ModelProtocol>(with id: Object.Id) -> Model? {
        self.values.first(where: { ($0 as? Model)?.id == id }) as? Model
    }

    open func add<Model: ModelProtocol>(model: Model) {
        self.values.append(model)
    }

    open func remove<Model: ModelProtocol>(model: Model) {
        self.values = self.values.filter({ $0 as? Model !== model })
    }
}

open class DictionaryModelCache: ModelCache {
    public init(_ values: [Object.Id: ModelProtocol]? = nil) {
        self.values = values ?? [:]
    }

    open var values: [Object.Id: ModelProtocol]

    open func model<Model: ModelProtocol>(with id: Object.Id) -> Model? {
        self.values[id] as? Model
    }

    open func add<Model: ModelProtocol>(model: Model) {
        if let id: Object.Id = model.id { self.values[id] = model }
    }

    open func remove<Model: ModelProtocol>(model: Model) {
        if let id: Object.Id = model.id { self.values.removeValue(forKey: id) }
    }
}
