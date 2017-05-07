import Store
import CoreData
import Foundation

open class MigrationUtility
{

    /*
    Sets up persistent store at the given url with specified name and schema, returns store url. Will copy existing store 
    file if it's found in migration test directory or will create new one otherwise.
    */
    open static func setUpPersistentStore(url: URL, name: String, schema: Schema) -> URL {
        let destinationStoreUrl: URL = url.appendingPathComponent("\(name).sqlite", isDirectory: false)
        let destinationSupportUrl: URL = url.appendingPathComponent(".\(name)_SUPPORT", isDirectory: true)

        // If we have an existing data snapshot in `test/migration` folder we copy it across along with support
        // data, otherwise we create a new store, check if we have a testing data class available and set up
        // data for the newly created store if we can.

        let sourceStoreUrl: URL = PathUtility.testUrl(directory: "migration", file: destinationStoreUrl.lastPathComponent)
        let sourceSupportUrl: URL = PathUtility.testUrl(directory: "migration/\(destinationSupportUrl.lastPathComponent)")
        let fileManager: FileManager = FileManager.default

        if !fileManager.fileExists(atPath: url.path) {
            try! fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }

        if fileManager.fileExists(atPath: sourceStoreUrl.path) && fileManager.fileExists(atPath: sourceSupportUrl.path) {
            try! fileManager.copyItem(at: sourceStoreUrl, to: destinationStoreUrl)
            try! fileManager.copyItem(at: sourceSupportUrl, to: destinationSupportUrl)
        } else {
            let coordinator: Coordinator = NSPersistentStoreCoordinator(managedObjectModel: schema)
            try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: destinationStoreUrl, options: nil)
        }

        return destinationStoreUrl
    }

    /*
    Creates persistent stores at the specified url from the given managed object models using model index as version
    identifier in the store name. Returns store urls for each found schema and that schema along with it.
    */
    open static func setUpPersistentStores(url: URL) -> [(URL, Schema)] {
        return Schema.schemas(at: PathUtility.librarySchemaUrl).map({ return (self.setUpPersistentStore(url: url, name: $1.deletingPathExtension().lastPathComponent, schema: $0), $0) })
    }
}