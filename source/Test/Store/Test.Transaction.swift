import Store
import Foundation
import Nimble

internal class TransactionTestCase: TestCase, PersistentStoreTestCase {
    internal static let schemaUrl: URL = PathUtility.librarySchemaUrl

    internal func test() {
        try! transaction({
            (0 ..< 5).forEach({ _ in try! BookModel.fake().save() })
        })
    }

    internal func testPerformance() {
        var models: [BookModel] = []
        let books: Int = 10
        let authors: Int = 10

        self.measure(description: "Generate:", block: {
            models = (0 ..< books).map({ _ in BookModel.fake(authors: (0 ..< authors).map({ _ in AuthorModel.fake() })) })
        })

        self.measure(description: "Save w/o transaction:", block: {
            models.forEach({
                $0.authors.forEach({ try! $0.save() })
                try! $0.save()
            })
        })

        self.measure(description: "Generate:", block: {
            models = (0 ..< books).map({ _ in BookModel.fake(authors: (0 ..< authors).map({ _ in AuthorModel.fake() })) })
        })

        self.measure(description: "Save w. transaction:", block: {
            try! transaction({
                models.forEach({
                    $0.authors.forEach({ try! $0.save() })
                    try! $0.save()
                })
            })
        })
    }

    private func measure(description: String, block: () -> Void) {
        let date: Date = Date()
        let interval: TimeInterval

        block()
        interval = date.timeIntervalSinceNow

        Swift.print(description, interval)
    }
}
