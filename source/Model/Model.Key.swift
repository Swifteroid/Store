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