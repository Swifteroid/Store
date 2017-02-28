import CoreData
import Foundation
import Nimble
import Store

internal class BookModelTestCase: ModelTestCase
{
    internal func test() {
        let books: [BookModel] = Array(0 ..< 10).map({ BookModel(title: "Title \($0)", author: "Author \($0)", publisher: "Publisher \($0)") })
        var batch: BookBatch

        batch = BookBatch(models: books)
        try! batch.save()
        expect(batch.models.map({ $0.id })).toNot(allPass(beNil()))

        batch = BookBatch(models: books)
        try! batch.load()
        expect(batch.models).to(haveCount(10))
        expect(batch.models.first?.author).toNot(beNil())
        expect(batch.models.first?.publisher).toNot(beNil())
        expect(batch.models.first?.title).toNot(beNil())

        try! batch.delete()
        expect(batch.models).to(beEmpty())

        try! batch.load()
        expect(batch.models).to(beEmpty())
    }
}