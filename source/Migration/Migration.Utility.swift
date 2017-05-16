import CoreData
import Foundation

/// Migration utility is very useful for testing data migrations and creating initial stores with different schema 
/// versions. The very basic testing approach is to ensure that store for each schema can be migrated without any
/// faults.
///
///     import Nimble
///
///     let storeUrl: URL = URL(fileURLWithPath: "…/migration/output")
///     let schemaUrl: URL = Bundle.main.url(forResource: "main", withExtension: "momd")!
///     let templateUrl: URL = URL(fileURLWithPath: "…/migration/template")
///     let stores: [(URL, Schema)] = MigrationUtility.setUpPersistentStores(at: storeUrl, schema: Schema.schemas(at schemaUrl), template: templateUrl)
///
///     for url in stores.map({ $0.0 }) {
///         expect(expression: { try Migration().migrate(store: url, schemas: schemas) }).toNot(throwError())
///     }
///
/// - See: Test.Migration.swift for an actual example. 

open class MigrationUtility
{

    /// Sets up persistent store at the given url with specified name and schema, returns store url. Will copy existing store 
    /// file if it's found in specified template directory or will create new one otherwise.
    ///
    /// - Parameter at: Destination directory where persistent store will be created.
    /// - Parameter name: Store filename without extension.
    /// - Parameter schema: Schema to use for creating new store or validating the template.
    /// - Parameter template: Template directory from where stores with the same name will be copied to destination directory.
    ///
    /// - Returns: Created store url. 

    open static func setUpPersistentStore(at storeUrl: URL, name: String, schema: Schema, template templateUrl: URL? = nil) -> URL? {
        let destinationStoreUrl: URL = storeUrl.appendingPathComponent("\(name).sqlite", isDirectory: false)
        let destinationSupportUrl: URL = storeUrl.appendingPathComponent(".\(name)_SUPPORT", isDirectory: true)
        let fileManager: FileManager = FileManager.default

        if !fileManager.fileExists(atPath: storeUrl.path) {
            try! fileManager.createDirectory(at: storeUrl, withIntermediateDirectories: true)
        }

        // If we have an existing data snapshot in `test/migration` folder we copy it across along with support
        // data, otherwise we create a new store, check if we have a testing data class available and set up
        // data for the newly created store if we can.

        let templateStoreUrl: URL? = templateUrl?.appendingPathComponent(destinationStoreUrl.lastPathComponent, isDirectory: false)
        let templateSupportUrl: URL? = templateUrl?.appendingPathComponent(destinationSupportUrl.lastPathComponent, isDirectory: true)

        if let storeUrl: URL = templateStoreUrl, let supportUrl: URL = templateSupportUrl, fileManager.fileExists(atPath: storeUrl.path) && fileManager.fileExists(atPath: supportUrl.path) {
            try! fileManager.copyItem(at: storeUrl, to: destinationStoreUrl)
            try! fileManager.copyItem(at: supportUrl, to: destinationSupportUrl)
        }

        // Creates new store or validates that existing one is compatible with the specified schema. Todo: is this 
        // todo: the only / correct way of doing this?

        try! Coordinator(managedObjectModel: schema).addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: destinationStoreUrl)

        return destinationStoreUrl
    }

    /// Creates persistent stores at the specified url from the given managed object models using model index as version
    /// identifier in the store name. 
    ///
    /// - Returns: Created store urls for each found schema and that schema along with it.

    open static func setUpPersistentStores(at url: URL, schemas: [(Schema, URL)], template templateUrl: URL? = nil) -> [(URL, Schema)] {
        return schemas.map({ (self.setUpPersistentStore(at: url, name: $1.deletingPathExtension().lastPathComponent, schema: $0, template: templateUrl)!, $0) })
    }
}