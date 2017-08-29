import Foundation
import Store

internal class ModelTestCase: TestCase, PersistentStoreTestCase
{
    internal static let schemaUrl: URL = PathUtility.librarySchemaUrl
}