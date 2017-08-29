import CoreData

public protocol Model: class, Equatable, Hashable
{
    associatedtype Configuration: ModelConfiguration

    var id: Object.Id? { get set }
}

extension Model
{
    public var identified: Bool {
        return self.id != nil
    }
}

extension Model
{
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

public func ==<Lhs:Model, Rhs:Model>(lhs: Lhs, rhs: Rhs) -> Bool {
    return lhs === rhs
}

// MARK: -

public protocol ModelInitialiser
{
    init(id: Object.Id?)
}
