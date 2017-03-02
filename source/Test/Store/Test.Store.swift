import Store
import Foundation
import Nimble

internal class StoreTestCase: TestCase
{
    internal func test() {
        let storeUrl: URL = Coordinator.url(for: "Store - Test")
        let schemaUrl: URL = Bundle(for: type(of: self)).url(forResource: "library", withExtension: "momd")!
        let coordinator: Coordinator? = Coordinator(storeUrl: storeUrl, schemaUrl: schemaUrl, handler: { true })
        expect(coordinator).toNot(beNil())
    }
}