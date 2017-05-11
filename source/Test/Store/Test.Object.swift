import Store
import Nimble

internal class ObjectTestCase: TestCase, StoreTestCaseProtocol
{
    internal static let schemaUrl: URL = PathUtility.genericSchemaUrl

    internal func testKvc() {
        let coordinator: Coordinator = Coordinator.default
        let context: Context = Context(coordinator: coordinator, concurrency: .mainQueueConcurrencyType)
        let object: Object = Object(entity: coordinator.schema.entity(for: "Foo")!, insertInto: context)

        let _: String? = object.value(for: "optional")
        let _: String! = object.value(for: "required")
    }
}