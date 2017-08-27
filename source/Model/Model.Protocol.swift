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

public protocol ModelInitialiserProtocol
{
    init(id: Object.Id?)
}
