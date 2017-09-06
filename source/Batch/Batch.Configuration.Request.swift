import CoreData

public protocol BatchRequestConfiguration
{
    var request: Request.Configuration? { get }
}

extension NSFetchRequest where ResultType == Object
{
    public struct Configuration
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
}