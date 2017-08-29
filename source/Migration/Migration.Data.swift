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

open class AbstractMigrationData: MigrationData
{
    public required init() {
    }

    // MARK: -

    open func setUp(schema: Schema) -> Schema {

        // In most cases the use of migration data assumes working with raw managed objects, which also often use
        // custom object class name. Not resetting it will cause various issues when using the object, e.g., when
        // class is no longer available or when it has completely changed.

        for entity in schema.entities {
            entity.managedObjectClassName = NSStringFromClass(Object.self)
        }

        return schema
    }

    open func setUp(coordinator: Coordinator) {
        self.setUp(coordinator: coordinator, context: Context(coordinator: coordinator, concurrency: .mainQueueConcurrencyType))
    }

    open func setUp(coordinator: Coordinator, context: Context) {
        abort()
    }
}