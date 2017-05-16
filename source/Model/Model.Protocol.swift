import CoreData

public protocol ModelProtocol: class, Equatable, Hashable
{
    associatedtype Configuration: ModelConfigurationProtocol

    var id: Object.Id? { get set }
}

extension ModelProtocol
{
    public var identified: Bool {
        return self.id != nil
    }
}

extension ModelProtocol
{
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

public func ==<Lhs:ModelProtocol, Rhs:ModelProtocol>(lhs: Lhs, rhs: Rhs) -> Bool {
    return lhs === rhs
}

// MARK: -

public protocol ModelConfigurationProtocol
{
}

public struct NoConfiguration: ModelConfigurationProtocol
{
}

// MARK: -

public struct FetchConfiguration
{
    public var limit: Int?
    public var offset: Int?
    public var sort: [NSSortDescriptor]?

    public init(limit: Int? = nil, offset: Int? = nil, sort: [NSSortDescriptor]? = nil) {
        self.limit = limit
        self.offset = offset
        self.sort = sort
    }
}

public protocol ModelFetchConfigurationProtocol
{
    var fetch: FetchConfiguration? { get set }
}

