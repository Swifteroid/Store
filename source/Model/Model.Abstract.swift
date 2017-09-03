import Foundation

extension Abstract
{
    open class Model: Store.Model
    {
        open var id: Object.Id?

        // MARK: -

        public convenience init(id: Object.Id?) {
            self.init()
            self.id = id
        }
    }
}

extension Abstract.Model: Hashable
{
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

public func ==(lhs: Abstract.Model, rhs: Abstract.Model) -> Bool {
    return lhs === rhs
}

extension Abstract
{
    open class BatchConstructableModel: Model, Store.BatchConstructableModel
    {
        public required init(id: Object.Id? = nil) {
            super.init()
            self.id = id
        }
    }
}