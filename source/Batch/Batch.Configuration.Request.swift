import CoreData

public protocol BatchRequestConfiguration {
    var request: Request.Configuration? { get }
}

extension NSFetchRequest where ResultType == Object {
    public struct Configuration {
        public typealias Block = (_ request: Request) -> Void

        public var limit: Int?
        public var offset: Int?
        public var sort: [NSSortDescriptor]?
        public var block: Block?

        public init(limit: Int? = nil, offset: Int? = nil, sort: [NSSortDescriptor]? = nil, block: Block? = nil) {
            self.limit = limit
            self.offset = offset
            self.sort = sort
            self.block = block
        }
    }
}
