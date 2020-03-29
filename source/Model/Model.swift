import Foundation

open class Model: ModelProtocol {
    open var id: Object.Id?

    // MARK: -

    public convenience init(id: Object.Id?) {
        self.init()
        self.id = id
    }
}

extension Model: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public func == (lhs: Model, rhs: Model) -> Bool {
    lhs === rhs
}

open class BatchConstructableModel: Model, BatchConstructableModelProtocol {
    public required init(id: Object.Id? = nil) {
        super.init()
        self.id = id
    }
}
