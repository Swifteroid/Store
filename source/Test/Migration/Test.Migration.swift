import Store
import Foundation
import Nimble
import XCTest

internal class MigrationTestCase: ModelTestCase {
    internal func test() {

        // Make sure migration data is setup as expected during migration.

        let expectation = (
            data: self.expectation(description: "Migration data set up invocation"),
            policy: self.expectation(description: "Migration policy begin invocation")
        )

        expectation.policy.assertForOverFulfill = false

        MigrationData_1_0_0.callback = { expectation.data.fulfill() }
        MigrationPolicy_1_1_0.callback = { expectation.policy.fulfill() }

        // Prepare output directory and testing stores.

        let date: String = DateFormatter(dateFormat: "yyyy-MM-dd-HH-mm-ss").string(from: Date())
        let outputUrl: URL = PathUtility.outputUrl(directory: "migration", cleanup: true).appendingPathComponent(date)
        let schemaUrl: URL = PathUtility.librarySchemaUrl
        let templateUrl: URL = PathUtility.testUrl(directory: "migration")
        let stores: [(URL, Schema)] = MigrationUtility.setUpPersistentStores(at: outputUrl, schemas: Schema.schemas(at: schemaUrl), template: templateUrl)
        let schemas: [Schema] = stores.map({ $0.1 })

        expect(schemas).toNot(beEmpty())

        // Todo: running this without errors is great, but would be good to have actual tests to verify it has worked.

        for url in stores.map({ $0.0 }) {
            expect({ try Migration().migrate(store: url, schemas: schemas) }).toNot(throwError())
        }

        self.waitForExpectations(timeout: 0)
    }
}

// MARK: -

extension DateFormatter {
    fileprivate convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
    }
}
