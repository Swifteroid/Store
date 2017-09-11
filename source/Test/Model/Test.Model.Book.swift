import Foundation
import Nimble
import Store

internal class BookModelTestCase: ModelTestCase
{
    internal func test() {
        self.test((0 ..< 10).map({ _ in BookModel.fake() }), {
            expect($0.title).toNot(beNil())
            expect($0.publisher).toNot(beNil())
            expect($0.authors).toNot(beEmpty())
        })
    }

    internal func testFind() {
        let books: [BookModel] = (0 ..< 10).map({ _ in try! BookModel.fake().save() })
        expect(try BookBatch().find(title: books[5].title).models[0].title).to(equal(books[5].title))
    }
}