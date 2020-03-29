import Store
import XCTest

internal class TestCase: XCTestCase {
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

internal protocol PersistentStoreTestCase {
    static var schemaUrl: URL { get }
}

extension PersistentStoreTestCase {
    internal static func setUp() {
        let fileManager: FileManager = FileManager.default
        let storeUrl: URL = Coordinator.url(for: "Store - Test")
        if fileManager.fileExists(atPath: storeUrl.deletingLastPathComponent().path) { try! fileManager.removeItem(at: storeUrl.deletingLastPathComponent()) }
        Coordinator.default = Coordinator(store: storeUrl, schema: self.schemaUrl, handler: { true })!
    }

    internal static func tearDown() {
        if let coordinator: Coordinator = Coordinator.default {
            coordinator.persistentStores.forEach({ try! coordinator.remove($0) })
            Coordinator.default = nil
        }
    }
}
