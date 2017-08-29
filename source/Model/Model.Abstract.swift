import Foundation

open class AbstractModel<ConfigurationType:ModelConfiguration>: Model
{
    public typealias Configuration = ConfigurationType

    open var id: Object.Id?

    // MARK: -

    public convenience init(id: Object.Id?) {
        self.init()
        self.id = id
    }
}

open class InitialisableModel<ConfigurationType:ModelConfiguration>: AbstractModel<ConfigurationType>, ModelInitialiser
{
    public required init(id: Object.Id? = nil) {
        super.init()
        self.id = id
    }
}