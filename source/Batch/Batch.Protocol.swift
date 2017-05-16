import Foundation

public protocol BatchProtocol: class
{
    associatedtype Model: ModelProtocol
    associatedtype Configuration: ModelConfigurationProtocol = Model.Configuration

    var models: [Model] { get set }

    var remodels: [Model] { get set }

    init(models: [Model]?, remodels: [Model]?)

    func exist(models: [Model]?) -> Bool
    func exists(model: Model) -> Bool

    @discardableResult func load(configuration: Configuration?) throws -> Self
    @discardableResult func save(configuration: Configuration?) throws -> Self
    @discardableResult func delete(configuration: Configuration?) throws -> Self

    @discardableResult func construct(with object: Object, configuration: Configuration?) -> Model
    @discardableResult func update(model: Model, with object: Object, configuration: Configuration?) -> Model
    @discardableResult func update(object: Object, with model: Model, configuration: Configuration?) -> Object
}

// MARK: -

extension BatchProtocol
{
    public func exists(model: Model) -> Bool {
        return self.exist(models: [model])
    }

    public init() {
        self.init(models: [], remodels: [])
    }

    public init(models: [Model]) {
        self.init(models: models, remodels: [])
    }

    public init(remodels: [Model]) {
        self.init(models: [], remodels: remodels)
    }
}

// MARK: -

public protocol InitialisableProtocol
{
    init()
}

// MARK: -

public protocol BatchableProtocol: ModelProtocol
{
    associatedtype Batch: BatchProtocol

    var exists: Bool { get }
}

extension BatchableProtocol where Batch.Model == Self, Batch.Configuration == Self.Configuration
{
    public var exists: Bool {
        return (Batch(models: []) as Batch).exist(models: [self])
    }

    @discardableResult public func load(configuration: Configuration? = nil) throws -> Self {
        try (Batch(models: [self]) as Batch).load(configuration: configuration)
        return self
    }

    @discardableResult public func save(configuration: Configuration? = nil) throws -> Self {
        try Batch(models: [self]).save(configuration: configuration)
        return self
    }

    @discardableResult public func delete(configuration: Configuration? = nil) throws -> Self {
        try (Batch(models: [self]) as Batch).delete(configuration: configuration)
        return self
    }
}

// MARK: -

public struct BatchNotification
{
    public static let willSaveContext: Notification.Name = Notification.Name("BatchWillSaveNotification")
}

extension BatchNotification
{
    public struct Key
    {
        public static let context: String = "context"
    }
}