import CoreData

public protocol MigrationDataProtocol: class
{
    init()

    func setUp(coordinator: Coordinator)
}

/// Migration data is a counterpart of migration utility and primarily focused on construction of migration 
/// testing data. Override set up method with custom logic to insert or update stored data before attempting
/// to migrate it.

open class MigrationData: MigrationDataProtocol
{
    public required init() {
    }

    // MARK: -

    open func setUp(coordinator: Coordinator) {
        self.setUp(coordinator: coordinator, context: Context(coordinator: coordinator, concurrency: .mainQueueConcurrencyType))
    }

    open func setUp(coordinator: Coordinator, context: Context) {
        abort()
    }
}