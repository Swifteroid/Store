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

            // Verify that copied store schema is compatible with current schema. 

            if !schema.compatible(with: try! Coordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: destinationStoreUrl)) {
                return nil
            }
        }

        // Creates new store or validates that existing one is compatible with the specified schema.

        let data: MigrationDataProtocol? = self.data(for: name)
        let schema: Schema = data?.setUp(schema: schema) ?? schema
        let coordinator: Coordinator = Coordinator(managedObjectModel: schema)

        try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: destinationStoreUrl)
        data?.setUp(coordinator: coordinator)

        return destinationStoreUrl
    }

    /// Creates persistent stores at the specified url from the given managed object models using model index as version
    /// identifier in the store name. 
    ///
    /// - Returns: Created store urls for each found schema and that schema along with it.

    open static func setUpPersistentStores(at url: URL, schemas: [(Schema, URL)], template templateUrl: URL? = nil) -> [(URL, Schema)] {
        return schemas.map({ (self.setUpPersistentStore(at: url, name: $1.deletingPathExtension().lastPathComponent, schema: $0, template: templateUrl)!, $0) })
    }

    // MARK: -

    private static var dataModuleNames: [String] = []

    /// Looks up for the named migration data class and returns an instance.

    open static func data(for name: String) -> MigrationDataProtocol? {
        let className: String = "\(MigrationData.self)_\(name.replacingOccurrences(of: ".", with: "_"))"

        // There is an easy and not so easy way of doing this. First is to check and just see if we have the required 
        // class. This typically would fail, because this class would usually be in another bundle and will simply not 
        // be recognised unless we specify module name, which we can't find out easily. Lastly we can check all loaded 
        // classes and try to match our one and save it's module name for later magic.

        if let DataClass: MigrationDataProtocol.Type = NSClassFromString(className) as? MigrationDataProtocol.Type {
            return DataClass.init()
        }

        for moduleName in self.dataModuleNames {
            if let DataClass: MigrationDataProtocol.Type = NSClassFromString("\(moduleName).\(className)") as? MigrationDataProtocol.Type {
                return DataClass.init()
            }
        }

        let classCount: Int = Int(objc_getClassList(nil, 0))
        let classes: AutoreleasingUnsafeMutablePointer<AnyClass> = AutoreleasingUnsafeMutablePointer(UnsafeMutablePointer<AnyClass>.allocate(capacity: classCount))

        objc_getClassList(classes, Int32(classCount))

        for i in 0 ..< classCount {
            if let DataClass: MigrationDataProtocol.Type = classes[i] as? MigrationDataProtocol.Type {

                // We know this is a migration data class and now is a good idea to save to get the module name
                // and cache it in known data module name list for later reuse.

                let fullClassName: String = NSStringFromClass(DataClass)
                let expression: NSRegularExpression = try! NSRegularExpression(pattern: "^(\\w+)\\..+$")
                var moduleName: String?

                if let match: NSTextCheckingResult = expression.firstMatch(in: fullClassName, range: NSRange(location: 0, length: fullClassName.count)) {
                    moduleName = (fullClassName as NSString).substring(with: match.range(at: 1))

                    if self.dataModuleNames.contains(moduleName!) {
                        moduleName = nil
                    } else {
                        self.dataModuleNames.append(moduleName!)
                    }
                }

                // If class name matches, then great, return it! Otherwise if we know this is a new module name
                // then we can attempt to rematch class with that module name to avoid further iterations.

                if fullClassName.hasSuffix(className) {
                    return DataClass.init()
                } else if let moduleName: String = moduleName, let DataClass: MigrationDataProtocol.Type = NSClassFromString("\(moduleName).\(className)") as? MigrationDataProtocol.Type {
                    return DataClass.init()
                }
            }
        }

        return nil
    }
}