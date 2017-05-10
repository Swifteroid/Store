import Foundation

open class Model<ConfigurationType:ModelConfigurationProtocol>: NSObject, ModelProtocol
{
    public typealias Configuration = ConfigurationType

    /*
    String representable of core data object id.
    */
    open var id: String?

    // MARK: -

    public convenience init(id: String?) {
        self.init()
        self.id = id
    }
}

open class InitialisableModel<ConfigurationType:ModelConfigurationProtocol>: Model<ConfigurationType>, InitialisableProtocol
{
    override public required init() {
        super.init()
    }
}