import Store
import XCTest

internal class TestCase: XCTestCase
{
    override internal class func setUp() {
        if let StoreTestCase: StoreTestCaseProtocol.Type = self as? StoreTestCaseProtocol.Type {
            StoreTestCase.setUp()
        }
    }

    override internal class func tearDown() {
        if let StoreTestCase: StoreTestCaseProtocol.Type = self as? StoreTestCaseProtocol.Type {
            StoreTestCase.tearDown()
        }
    }
}

// MARK: -

internal protocol StoreTestCaseProtocol
{
    static var schemaUrl: URL { get }
}

extension StoreTestCaseProtocol
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