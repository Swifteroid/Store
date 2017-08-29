import CoreData

public protocol ModelConfiguration
{
}

public struct NoConfiguration: ModelConfiguration
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

public protocol ModelFetchConfiguration
{
    var fetch: FetchConfiguration? { get set }
}