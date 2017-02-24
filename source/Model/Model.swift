open class Model
{

    /*
    String representable of core data object id.
    */
    open var id: String?

    open var identified: Bool {
        return self.id != nil
    }

    // MARK: -

    public init(id: String? = nil) {
        self.id = id
    }

    // MARK: -

    @discardableResult open func load<Configuration>(configuration: Configuration? = nil) throws -> Self {
        try ModelSet<Model, Configuration>(models: [self]).load(configuration: configuration)
        return self
    }

    @discardableResult open func save<Configuration>(configuration: Configuration? = nil) throws -> Self {
        try ModelSet<Model, Configuration>(models: [self]).save(configuration: configuration)
        return self
    }

    @discardableResult open func delete<Configuration>(configuration: Configuration? = nil) throws -> Self {
        try ModelSet<Model, Configuration>(models: [self]).delete(configuration: configuration)
        return self
    }
}