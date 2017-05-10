import Foundation

public protocol BatchProtocol: class
{
    associatedtype Model: ModelProtocol

    var models: [Model] { get set }

    init(models: [Model])

    func exist(models: [Model]?) -> Bool
    func exists(model: Model) -> Bool

    @discardableResult func load(configuration: Model.Configuration?) throws -> Self
    @discardableResult func save(configuration: Model.Configuration?) throws -> Self
    @discardableResult func delete(configuration: Model.Configuration?) throws -> Self

    @discardableResult func construct(with object: Object, configuration: Model.Configuration?) -> Model
    @discardableResult func update(model: Model, with object: Object, configuration: Model.Configuration?) -> Model
    @discardableResult func update(object: Object, with model: Model, configuration: Model.Configuration?) -> Object
}

extension BatchProtocol
{
    public func exists(model: Model) -> Bool {
        return self.exist(models: [model])
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

extension BatchableProtocol
{
    public var exists: Bool {
        return (Batch(models: []) as Batch).exist(models: [self as! Batch.Model])
    }

    @discardableResult public func load(configuration: Batch.Model.Configuration? = nil) throws -> Self {
        try (Batch(models: [self as! Batch.Model]) as Batch).load(configuration: configuration)
        return self
    }

    @discardableResult public func save(configuration: Batch.Model.Configuration? = nil) throws -> Self {
        try Batch(models: [self as! Batch.Model]).save(configuration: configuration)
        return self
    }

    @discardableResult public func delete(configuration: Batch.Model.Configuration? = nil) throws -> Self {
        try (Batch(models: [self as! Batch.Model]) as Batch).delete(configuration: configuration)
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