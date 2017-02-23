import CoreData
import Foundation

/*
 - https://kean.github.io/blog/core-data-progressive-migrations
 - https://www.objc.io/issues/4-core-data/core-data-migration/
 - https://izeeshan.wordpress.com/2014/11/10/core-data-migration/
 - http://9elements.com/io/index.php/customizing-core-data-migrations/
 - http://themainthread.com/blog/2014/03/replacing-a-core-data-store.html
 */
open class Migration
{

    /*
    Migrates data store at the given url using specified schemas with identifiers, managed object models must
    be ordered by their version, identifiers are used primarily for logging.
    */
    open func migrate(store: URL, schemas: [(NSManagedObjectModel, URL)]) throws -> NSManagedObjectModel? {

        // First things first, we must figure what schema is used with data store. We do this in reverse order, because
        // if for whatever reason the earlier schema will be compatible, we will be migrating our data in loops, potentially
        // damaging it along the way.

        let metadata: [String: AnyObject] = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: store) as [String: AnyObject]
        let index: Int = schemas.reversed().index(where: { $0.0.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) }) ?? -1

        if index == -1 {
            throw Error.noCompatibleManagedObjectModel
        } else if index == 0 {
            return schemas.last!.0
        }

        let fileManager: FileManager = FileManager.default
        let dateFormatter: DateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd-HH-mm-ss")

        let backupUrl: URL = store.deletingLastPathComponent()
            .appendingPathComponent("Backup", isDirectory: true)
            .appendingPathComponent("\(store.deletingPathExtension().lastPathComponent) - \(dateFormatter.string(from: Date()))", isDirectory: false)
            .appendingPathExtension(store.pathExtension)

        guard fileManager.directoryExists(atUrl: backupUrl.deletingLastPathComponent(), create: true) else { return nil }
        try! fileManager.copyItem(at: store, to: backupUrl)

        for i in schemas.count - 1 - index ..< schemas.count - 1 {
            let sourceSchema: NSManagedObjectModel = schemas[i].0
            let destinationSchema: NSManagedObjectModel = schemas[i + 1].0

            let migrationManager: NSMigrationManager = NSMigrationManager(sourceModel: sourceSchema, destinationModel: destinationSchema)
            let mappingModel: NSMappingModel = self.getMappingModel(source: sourceSchema, destination: destinationSchema)

            let temporaryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
            let migrationUrl: URL = temporaryUrl.appendingPathComponent(store.lastPathComponent)

            guard fileManager.directoryExists(atUrl: temporaryUrl, create: true) else { return nil }

            try! migrationManager.migrateStore(
                from: store,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: mappingModel,
                toDestinationURL: migrationUrl,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil)

            // Replace source store.

            if #available(OSX 10.11, *) {
                try! NSPersistentStoreCoordinator(managedObjectModel: destinationSchema).replacePersistentStore(
                    at: store,
                    destinationOptions: nil,
                    withPersistentStoreFrom: migrationUrl,
                    sourceOptions: nil,
                    ofType: NSSQLiteStoreType)
            } else {
                try! fileManager.removeItem(at: store)
                try! fileManager.moveItem(at: migrationUrl, to: store)
            }

            try! fileManager.removeItem(at: temporaryUrl)
        }

        return schemas.last!.0
    }

    open func getMappingModel(source: NSManagedObjectModel, destination: NSManagedObjectModel) -> NSMappingModel {
        let mappingModel: NSMappingModel? = NSMappingModel(from: Bundle.allBundles, forSourceModel: source, destinationModel: destination)
        return mappingModel ?? (try! NSMappingModel.inferredMappingModel(forSourceModel: source, destinationModel: destination))
    }

    public init() {
    }
}

extension Migration
{
    public enum Error: Swift.Error
    {
        case noCompatibleManagedObjectModel
    }
}

extension DateFormatter
{
    fileprivate convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
    }
}