import CoreData

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