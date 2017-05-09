import Foundation

open class Model<ConfigurationType:ModelConfigurationProtocol>: NSObject, ModelProtocol
{
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
}