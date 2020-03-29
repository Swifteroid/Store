import Store
import Nimble

internal class ObjectTestCase: TestCase, PersistentStoreTestCase {
    internal static let schemaUrl: URL = PathUtility.genericSchemaUrl

    internal func testKvc() {
        let coordinator: Coordinator = Coordinator.default
        let context: Context = Context(coordinator: coordinator, concurrency: .privateQueueConcurrencyType)
        let object: Object = Object(entity: coordinator.schema.entity(for: "Foo")!, insertInto: context)

        // Test optional accessor.

        let _: String? = object.value(for: "optional")
        let _: String! = object.value(for: "required")

        // Test transformer.

        let url: URL = URL(string: "foo")!
        object.value(set: url, for: "url", transform: { $0.path })
        let _: URL = object.value(for: "url", transform: { URL(string: $0) })!
    }
}
