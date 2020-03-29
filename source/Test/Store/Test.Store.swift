import Store
import Foundation
import Nimble

internal class StoreTestCase: TestCase {
    internal func test() {
        let storeUrl: URL = Coordinator.url(for: "Store - Test")
        let schemaUrl: URL = PathUtility.librarySchemaUrl
        let coordinator: Coordinator? = Coordinator(store: storeUrl, schema: schemaUrl, handler: { true })
        expect(coordinator).toNot(beNil())
    }
}
