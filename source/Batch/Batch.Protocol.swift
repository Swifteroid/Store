import Foundation

public protocol BatchProtocol: class
{
    associatedtype Model: ModelProtocol

    var models: [Model] { get set }

    init(models: [Model])
}

extension BatchProtocol
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