import CoreData

/// Migration data is a counterpart of migration utility and primarily focused on construction of migration 
/// testing data. Override set up method with custom logic to insert or update stored data before attempting
/// to migrate it.

public protocol MigrationData: class
{
    init()

    /// Sets up schema before it gets used to initialise the coordinator.

    func setUp(schema: Schema) -> Schema

    /// Sets up data.

    func setUp(coordinator: Coordinator)
}