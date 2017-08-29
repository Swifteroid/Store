import Store
import XCTest

internal class TestCase: XCTestCase
{
    override internal class func setUp() {
        if let StoreTestCase: PersistentStoreTestCase.Type = self as? PersistentStoreTestCase.Type {
            StoreTestCase.setUp()
        }
    }

    override internal class func tearDown() {
        if let StoreTestCase: PersistentStoreTestCase.Type = self as? PersistentStoreTestCase.Type {
            StoreTestCase.tearDown()
        }
    }
}

// MARK: -

internal protocol PersistentStoreTestCase
{
    static var schemaUrl: URL { get }
}

extension PersistentStoreTestCase
{
    internal static func setUp() {
        let storeUrl: URL = Coordinator.url(for: "Store - Test")
        try! FileManager.default.removeItem(at: storeUrl)
        Coordinator.default = Coordinator(store: storeUrl, schema: self.schemaUrl, handler: { true })!
    }

    internal static func tearDown() {
        if let coordinator: Coordinator = Coordinator.default {
            coordinator.persistentStores.forEach({ try! coordinator.remove($0) })
            Coordinator.default = nil
        }
    }
}