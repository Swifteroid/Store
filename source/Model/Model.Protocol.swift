public protocol ModelProtocol: class
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

// MARK: -

public protocol ModelConfigurationProtocol
{
}

public struct NoConfiguration: ModelConfigurationProtocol
{
}