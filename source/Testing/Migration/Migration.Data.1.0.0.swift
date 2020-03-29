import CoreData
import Store

internal class MigrationData_1_0_0: MigrationData {
    internal static var callback: (() -> Void)?

    override internal func setUp(coordinator: Coordinator, context: Context) {
        type(of: self).callback?()
    }
}
