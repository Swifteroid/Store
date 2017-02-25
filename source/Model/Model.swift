import Foundation

open class Model<KeyType:ModelKeyProtocol, ConfigurationType:ModelConfigurationProtocol>: ModelProtocol where KeyType.Configuration == ConfigurationType
{
    public typealias Key = KeyType
    public typealias Configuration = ConfigurationType

    /*
    String representable of core data object id.
    */
    open var id: String?

    // MARK: -

    public init(id: String? = nil) {
        self.id = id
    }

    // MARK: -

    open subscript(key: Key) -> Any? {
        get { abort() }
        set { abort() }
    }
}