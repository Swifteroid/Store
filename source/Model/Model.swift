import Foundation

open class Model<KeyType:ModelKeyProtocol, ConfigurationType:ModelConfigurationProtocol>: NSObject, ModelProtocol where KeyType.Configuration == ConfigurationType
{
    public typealias Key = KeyType
    public typealias Configuration = ConfigurationType

    /*
    String representable of core data object id.
    */
    open var id: String?

    // MARK: -

    override public init() {
        super.init()
    }

    public init(id: String?) {
        super.init()
        self.id = id
    }

    // MARK: -

    open subscript(key: Key) -> Any? {
        get {
            return self.value(forKey: key.rawValue as! String)
        }
        set {
            self.setValue(newValue, forKey: key.rawValue as! String)
        }
    }
}