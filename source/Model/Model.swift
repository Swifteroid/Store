import Foundation

open class Model<ConfigurationType:ModelConfigurationProtocol>: ModelProtocol
{
    public typealias Configuration = ConfigurationType

    open var id: Object.Id?

    // MARK: -

    public convenience init(id: Object.Id?) {
        self.init()
        self.id = id
    }
}

open class InitialisableModel<ConfigurationType:ModelConfigurationProtocol>: Model<ConfigurationType>, ModelInitialiserProtocol
{
    public required init(id: Object.Id? = nil) {
        super.init()
        self.id = id
    }
}