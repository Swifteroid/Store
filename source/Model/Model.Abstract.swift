import Foundation

open class AbstractModel
{
    open var id: Object.Id?

    // MARK: -

    public convenience init(id: Object.Id?) {
        self.init()
        self.id = id
    }
}

extension AbstractModel: Hashable
{
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

public func ==(lhs: AbstractModel, rhs: AbstractModel) -> Bool {
    return lhs === rhs
}

open class AbstractBatchConstructableModel: AbstractModel, BatchConstructableModel
{
    public required init(id: Object.Id? = nil) {
        super.init()
        self.id = id
    }
}