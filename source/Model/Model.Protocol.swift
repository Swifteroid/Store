public protocol ModelProtocol: class, Equatable
{
    associatedtype Configuration: ModelConfigurationProtocol

    var id: String? { get set }
}

extension ModelProtocol
{
    public var identified: Bool {
        return self.id != nil
    }
}

public func ==<Lhs:ModelProtocol, Rhs:ModelProtocol>(lhs: Lhs, rhs: Rhs) -> Bool {
    return lhs === rhs
}

// MARK: -

public protocol ModelConfigurationProtocol
{
}

public struct NoConfiguration: ModelConfigurationProtocol
{
}