import CoreData

public protocol Identified: class
{
    var id: Object.Id? { get set }
}

extension Identified
{
    public var identified: Bool {
        return self.id != nil
    }
}

// MARK: -

public protocol Model: class, Identified, Equatable, Hashable
{
    associatedtype Configuration: ModelConfiguration
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
