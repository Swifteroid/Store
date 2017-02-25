import Foundation

public protocol ModelSetProtocol: class
{
    associatedtype Model: ModelProtocol

    var models: [Model] { get set }

    init(models: [Model])
}

extension ModelSetProtocol
{
    @discardableResult public func load(configuration: Model.Configuration? = nil) throws -> Self {
        abort()
    }

    @discardableResult public func save(configuration: Model.Configuration? = nil) throws -> Self {
        abort()
    }

    @discardableResult public func delete(configuration: Model.Configuration? = nil) throws -> Self {
        abort()
    }
}

// MARK: -

public protocol ModelSetElementProtocol: ModelProtocol
{
    associatedtype Set: ModelSetProtocol
}

extension ModelSetElementProtocol
{
    @discardableResult public func load(configuration: Set.Model.Configuration? = nil) throws -> Self {
        try Set(models: [self as! Set.Model]).load(configuration: configuration)
        return self
    }

    @discardableResult public func save(configuration: Set.Model.Configuration? = nil) throws -> Self {
        try Set(models: [self as! Set.Model]).save(configuration: configuration)
        return self
    }

    @discardableResult public func delete(configuration: Set.Model.Configuration? = nil) throws -> Self {
        try Set(models: [self as! Set.Model]).delete(configuration: configuration)
        return self
    }
}