import Foundation

public protocol Batch: class
{
    associatedtype Model: Store.Model
    associatedtype Configuration: ModelConfiguration = Model.Configuration

    init(coordinator: Coordinator?, context: Context?, cache: ModelCache?, models: [Model]?)

    var coordinator: Coordinator? { get set }

    var context: Context? { get set }

    var cache: ModelCache? { get set }

    var models: [Model] { get set }

    func exist(models: [Model]?) -> Bool
    func exists(model: Model) -> Bool

    @discardableResult func load(configuration: Configuration?) throws -> Self
    @discardableResult func save(configuration: Configuration?) throws -> Self
    @discardableResult func delete(configuration: Configuration?) throws -> Self

    @discardableResult func construct(with object: Object, configuration: Configuration?, cache: ModelCache?) -> Model
    @discardableResult func update(model: Model, with object: Object, configuration: Configuration?) -> Model
    @discardableResult func update(object: Object, with model: Model, configuration: Configuration?) -> Object
}

// MARK: -

extension Batch
{
    public func exists(model: Model) -> Bool {
        return self.exist(models: [model])
    }

    public init(coordinator: Coordinator? = nil, context: Context? = nil, cache: ModelCache? = nil, models: [Model]? = nil) {
        self.init(coordinator: coordinator, context: context, cache: cache, models: models)
    }

    // MARK: -

    @discardableResult func construct(with object: Object, configuration: Configuration? = nil, cache: ModelCache? = nil) -> Model {
        return self.construct(with: object, configuration: configuration, cache: cache)
    }
}

// MARK: -

public protocol Batchable: Model
{
    associatedtype Batch: Store.Batch

    var exists: Bool { get }
}

extension Batchable where Batch.Model == Self, Batch.Configuration == Self.Configuration
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