import CoreData
import Foundation
import Store

internal class ModelTestCase: TestCase
{
    override internal class func setUp() {
        let storeUrl: URL = Coordinator.url(for: "Store - Test")
        let schemaUrl: URL = Bundle(for: self).url(forResource: "library", withExtension: "momd")!
        try! FileManager.default.removeItem(at: storeUrl)
        Coordinator.default = Coordinator(storeUrl: storeUrl, schemaUrl: schemaUrl, handler: { true })!
    }

    override internal class func tearDown() {
        if let coordinator: Coordinator = Coordinator.default {
            for store: NSPersistentStore in coordinator.persistentStores {
                try! coordinator.remove(store)
            }

            Coordinator.default = nil
        }
    }
}