import Foundation

public protocol ModelProtocol: class
{
    associatedtype Configuration: ModelConfigurationProtocol
    associatedtype Key: ModelKeyProtocol

    var id: String? { get set }

    subscript(key: Key) -> Any? { get set }
}

extension ModelProtocol
{
    public var identified: Bool {
        return self.id != nil
    }
}