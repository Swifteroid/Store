public protocol ModelProtocol: class
{
    associatedtype Configuration: ModelConfigurationProtocol
    associatedtype Key: ModelKeyProtocol

    var id: String? { get set }

    subscript(key: Key) -> Any? {
        get set
    }
}

extension ModelProtocol
{
    public var identified: Bool {
        return self.id != nil
    }
}

// MARK: -

public protocol ModelKeyProtocol: RawRepresentable
{
    associatedtype Configuration: ModelConfigurationProtocol
    typealias RawValue = String

    static var all: [Self] { get }
}

extension ModelKeyProtocol
{
    public static func `for`(configuration: Configuration?) -> [Self] {
        return self.all
    }
}

// MARK: -

public protocol ModelConfigurationProtocol
{
}

public struct NoConfiguration: ModelConfigurationProtocol
{
}