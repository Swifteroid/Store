import Store
import Foundation
import Nimble

internal class StoreTestCase: TestCase
{
    internal func test() {
        let storeUrl: URL = Store.url(for: "Store - Test")
        let schemaUrl: URL = Bundle(for: type(of: self)).url(forResource: "library", withExtension: "momd")!
        let store: Store? = Store(storeUrl: storeUrl, schemaUrl: schemaUrl, handler: { true })
        expect(store).toNot(beNil())
    }
}