import CoreData

public typealias Coordinator = NSPersistentStoreCoordinator

private var coordinator: Coordinator!

extension Coordinator
{
    public convenience init(schema: Schema) {
        self.init(managedObjectModel: schema)
    }

    /*
    Sets up coordinator with store at the given url. If store already exists it will be automatically migrated to the latest schema found
    at specified schema url, typically compiled momd file. If it doesn't exist it will be created using the latest schema. Handler is invoked
    when migration fails and specifies whether store should be deleted, so it can be recreated. Inside it you can ask user if he really wants
    to delete broken data file or attempt to repair it.
    */
    public convenience init?(store storeUrl: URL, schema schemaUrl: URL, handler: () -> (Bool)) {
        let fileManager: FileManager = FileManager.default
        let schemas: [Schema] = Schema.schemas(at: schemaUrl).map({ $0.0 })
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
        } else if !fileManager.directoryExists(at: storeUrl.deletingLastPathComponent(), create: true) {
            return nil
        }

        if let schema: Schema = schema ?? schemas.last {
            self.init(managedObjectModel: schema)

            do {
                try self.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: nil)
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }

    // MARK: -

    open static var `default`: Coordinator! {
        get { return coordinator }
        set { coordinator = newValue }
    }

    open var schema: Schema {
        return self.managedObjectModel
    }

    // MARK: -

    /*
    Returns store url for specified application / domain name located in application support folder.
    */
    @nonobjc open class func url(for name: String, file: String? = nil) -> URL {

        // The directory the application uses to store the Core Data store file. This code uses a file 
        // named "Store.sqlite" in the application data directory.

        let url: URL = try! FileManager.default.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true)
        return url.appendingPathComponent(name, isDirectory: true).appendingPathComponent("\(file ?? "Store/Store").sqlite", isDirectory: false)
    }

    @nonobjc open class func url(for bundle: Bundle, file: String? = nil) -> URL {
        let name: String = bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? bundle.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as! String
        return self.url(for: name, file: file)
    }
}