import Foundation

open class Model<ConfigurationType:ModelConfigurationProtocol>: ModelProtocol
{
    public typealias Configuration = ConfigurationType

    /*
    String representable of core data object id.
    */
    open var id: Object.Id?

    // MARK: -

    public convenience init(id: Object.Id?) {
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