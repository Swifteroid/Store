import CoreData
import Store

internal class MigrationData_1_0_0: AbstractMigrationData
{
    internal static var callback: (() -> ())?

    override internal func setUp(coordinator: Coordinator, context: Context) {
        type(of: self).callback?()
    }
}