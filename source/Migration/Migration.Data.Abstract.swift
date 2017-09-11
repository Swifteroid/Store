import Foundation

extension Abstract
{
    open class MigrationData: Store.MigrationData
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
            let context: Context = Context(coordinator: coordinator, concurrency: .privateQueueConcurrencyType)
            context.performAndWait({ self.setUp(coordinator: coordinator, context: context) })
        }

        open func setUp(coordinator: Coordinator, context: Context) {
            abort()
        }
    }
}