import CoreData

internal class MigrationPolicy_1_1_0: NSEntityMigrationPolicy
{
    internal static var callback: (() -> ())?

    override func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws {
        type(of: self).callback?()
        try super.begin(mapping, with: manager)
    }
}