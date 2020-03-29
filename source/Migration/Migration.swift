import CoreData
import Foundation

/*
 - https://kean.github.io/blog/core-data-progressive-migrations
 - https://www.objc.io/issues/4-core-data/core-data-migration/
 - https://izeeshan.wordpress.com/2014/11/10/core-data-migration/
 - http://9elements.com/io/index.php/customizing-core-data-migrations/
 - http://themainthread.com/blog/2014/03/replacing-a-core-data-store.html
 */
open class Migration {

    /// Migrates data store at the given url using specified schemas and returns final schema used by the store, schemas must
    /// be ordered by their version.
    ///
    /// - Parameter bundle: Bundles where to look for mapping models, if there no mapping models, make sure to pass an
    ///   empty array, otherwise all bundles will be searched, which will result in some overhead.

    @discardableResult open func migrate(store: URL, schemas: [Schema], bundles: [Bundle]? = nil) throws -> Schema? {

        // First things first, we must figure what schema is used with data store. We do this in reverse order, because
        // if for whatever reason the earlier schema will be compatible, we will be migrating our data in loops, potentially
        // damaging it along the way.

        let metadata: [String: Any] = try Coordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: store)
        let index: Int = schemas.reversed().firstIndex(where: { $0.compatible(with: metadata) }) ?? -1

        if index == -1 {
            throw Error.noCompatibleSchema
        } else if index == 0 {
            return schemas.last!
        }

        let fileManager: FileManager = FileManager.default
        let dateFormatter: DateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd-HH-mm-ss")

        let backupUrl: URL = store.deletingLastPathComponent()
            .appendingPathComponent("Backup", isDirectory: true)
            .appendingPathComponent("\(store.deletingPathExtension().lastPathComponent) - \(dateFormatter.string(from: Date()))", isDirectory: false)
            .appendingPathExtension(store.pathExtension)

        guard fileManager.directoryExists(at: backupUrl.deletingLastPathComponent(), create: true) else {
            throw Error.file("Cannot provide backup directory for migration.")
        }

        try! fileManager.copyItem(at: store, to: backupUrl)

        for i in schemas.count - 1 - index ..< schemas.count - 1 {
            let sourceSchema: Schema = schemas[i]
            let destinationSchema: Schema = schemas[i + 1]

            let migrationManager: NSMigrationManager = NSMigrationManager(sourceModel: sourceSchema, destinationModel: destinationSchema)
            let mapping: NSMappingModel = self.mapping(from: sourceSchema, to: destinationSchema, in: bundles)

            let temporaryUrl: URL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
            let migrationUrl: URL = temporaryUrl.appendingPathComponent(store.lastPathComponent)

            guard fileManager.directoryExists(at: temporaryUrl, create: true) else {
                throw Error.file("Cannot provide temporary directory for migration.")
            }

            try! migrationManager.migrateStore(
                from: store,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: mapping,
                toDestinationURL: migrationUrl,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil)

            // Replace source store.

            if #available(OSX 10.11, *) {
                try! Coordinator(managedObjectModel: destinationSchema).replacePersistentStore(
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

        return schemas.last!
    }

    /// Find existing mapping model for two schemas or create an inferred one if it doesn't exist.

    open func mapping(from source: Schema, to destination: Schema, in bundles: [Bundle]? = nil) -> NSMappingModel {
        let bundles: [Bundle] = bundles ?? Bundle.allBundles + Bundle.allFrameworks
        let mapping: NSMappingModel? = NSMappingModel(from: bundles, forSourceModel: source, destinationModel: destination)
        return mapping ?? (try! NSMappingModel.inferredMappingModel(forSourceModel: source, destinationModel: destination))
    }

    public init() {
    }
}

extension Migration {
    public enum Error: Swift.Error {
        case noCompatibleSchema
        case file(String)
    }
}

extension DateFormatter {
    fileprivate convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
    }
}
