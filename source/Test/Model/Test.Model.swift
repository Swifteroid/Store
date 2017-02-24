import CoreData
import Foundation
import Store

internal class ModelTestCase: TestCase
{
    override internal class func setUp() {
        let storeUrl: URL = Store.url(for: "Store - Test")
        let schemaUrl: URL = Bundle(for: self).url(forResource: "library", withExtension: "momd")!
        try! FileManager.default.removeItem(at: storeUrl)
        Store.default = Store(storeUrl: storeUrl, schemaUrl: schemaUrl, handler: { true })!
    }

    override internal class func tearDown() {
        if let store: Store = Store.default {
            let coordinator: NSPersistentStoreCoordinator = store.coordinator

            for store: NSPersistentStore in store.coordinator.persistentStores {
                try! coordinator.remove(store)
            }

            Store.default = nil
        }
    }
}