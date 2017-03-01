import CoreData

open class Store
{
    open static var `default`: Store!

    open var coordinator: NSPersistentStoreCoordinator

    open var schema: Schema {
        return coordinator.managedObjectModel
    }

    public init(coordinator: NSPersistentStoreCoordinator) {
        self.coordinator = coordinator
    }

    public init?(storeUrl: URL, schemaUrl: URL, handler: () -> (Bool)) {
        let fileManager: FileManager = FileManager.default
        let schemas: [(Schema, URL)] = Schema.schemas(at: schemaUrl)
        var schema: Schema?

        // If we have store at the given url we wanna try migrating it, otherwise it will be created
        // and we must make sure that the folder exists.

        if fileManager.fileExists(atPath: storeUrl.path) {
            let migration: Migration = Migration()

            do {
                schema = try migration.migrate(store: storeUrl, schemas: schemas)
            } catch {
                if handler() {
                    do {
                        try fileManager.removeItem(at: storeUrl)
                    } catch {
                        return nil
                    }
                } else {
                    return nil
                }
            }
        } else if !fileManager.directoryExists(atUrl: storeUrl.deletingLastPathComponent(), create: true) {
            return nil
        }

        if let schema: Schema = schema ?? schemas.last?.0 {
            let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: schema)

            do {
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: nil)
            } catch {
                return nil
            }

            self.coordinator = coordinator
        } else {
            return nil
        }
    }

    // MARK: -

    /*
    Returns store url for specified application name.
    */
    open class func url(for name: String) -> URL {

        // The directory the application uses to store the Core Data store file. This code uses a file 
        // named "Store.sqlite" in the application data directory.

        let supportUrl: URL = try! FileManager.default.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true)
        let storeUrl: URL = supportUrl.appendingPathComponent(name, isDirectory: true).appendingPathComponent("Store", isDirectory: true)
        return storeUrl.appendingPathComponent("Store.sqlite", isDirectory: false)
    }
}