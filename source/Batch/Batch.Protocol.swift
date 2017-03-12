import Foundation

public protocol BatchProtocol: class
{
    associatedtype Model: ModelProtocol

    var models: [Model] { get set }

    init(models: [Model])

    @discardableResult func load(configuration: Model.Configuration?) throws -> Self

    @discardableResult func save(configuration: Model.Configuration?) throws -> Self

    @discardableResult func delete(configuration: Model.Configuration?) throws -> Self
}

// MARK: -

public protocol BatchableProtocol: ModelProtocol
{
    associatedtype Batch: BatchProtocol
}

extension BatchableProtocol
{
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