import Store
import Foundation
import Nimble

internal class MigrationTestCase: ModelTestCase
{
    internal func test() {

        // Prepare output directory and testing stores.

        let date: String = DateFormatter(dateFormat: "yyyy-MM-dd-HH-mm-ss").string(from: Date())
        let outputUrl: URL = PathUtility.outputUrl(directory: "migration", cleanup: true).appendingPathComponent(date)
        let stores: [(URL, Schema)] = MigrationUtility.setUpPersistentStores(url: outputUrl)
        let schemas: [Schema] = stores.map({ $0.1 })

        expect(schemas).toNot(beEmpty())

        // Todo: running this without errors is great, but would be good to have actual tests to verify it has worked.

        for url in stores.map({ $0.0 }) {
            let migration: Migration = Migration()
            expect(expression: { try migration.migrate(store: url, schemas: schemas) }).toNot(throwError())
        }
    }
}

// MARK: -

extension DateFormatter
{
    fileprivate convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
    }
}