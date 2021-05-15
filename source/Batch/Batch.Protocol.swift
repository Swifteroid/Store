import Foundation

public protocol BatchProtocol: AnyObject {
    associatedtype Model: ModelProtocol
    associatedtype Configuration

    init(coordinator: Coordinator?, context: Context?, cache: ModelCache?, models: [Model]?)

    var coordinator: Coordinator? { get set }

    var context: Context? { get set }

    var cache: ModelCache? { get set }

    var models: [Model] { get set }

    func exist(models: [Model]?) -> Bool
    func exists(model: Model) -> Bool

    func construct(with object: Object, configuration: Configuration?, cache: ModelCache?, update: Bool?) throws -> Model

    @discardableResult func load(configuration: Configuration?) throws -> Self
    @discardableResult func update(model: Model, with object: Object, configuration: Configuration?) throws -> Model

    @discardableResult func save(configuration: Configuration?) throws -> Self
    @discardableResult func update(object: Object, with model: Model, configuration: Configuration?) throws -> Object

    @discardableResult func delete(configuration: Configuration?) throws -> Self
}

// MARK: -

extension BatchProtocol {
    public func exists(model: Model) -> Bool {
        self.exist(models: [model])
    }

    public init(coordinator: Coordinator? = nil, context: Context? = nil, cache: ModelCache? = nil, models: [Model]? = nil) {
        self.init(coordinator: coordinator, context: context, cache: cache, models: models)
    }

    // MARK: -

    func construct(with object: Object, configuration: Configuration? = nil, cache: ModelCache? = nil, update: Bool? = nil) throws -> Model {
        try self.construct(with: object, configuration: configuration, cache: cache, update: update)
    }
}

// MARK: -

/// Batchable protocol is needed to separate associated batch type form the model. Batch deals solely with model, but concrete
/// models do implement batchable protocol purely to simplify individual CRUD operations.

public protocol Batchable: ModelProtocol {
    associatedtype Batch: BatchProtocol
    associatedtype Configuration = Self.Batch.Configuration

    var exists: Bool { get }
}

extension Batchable where Batch.Model == Self, Batch.Configuration == Self.Configuration {
    public var exists: Bool {
        (Batch(models: []) as Batch).exist(models: [self])
    }

    @discardableResult public func load(configuration: Configuration? = nil) throws -> Self {
        try Batch(models: [self]).load(configuration: configuration)
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

public struct BatchNotification {
    public static let willSaveContext: Notification.Name = Notification.Name("BatchWillSaveNotification")
}

extension BatchNotification {
    public struct Key {
        public static let context: String = "context"
    }
}
