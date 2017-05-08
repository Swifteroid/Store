import CoreData
import Foundation
import Nimble
import Store

internal class BookModelTestCase: ModelTestCase
{
    internal func test() {
        let book: BookModel = BookModel.fake()

        expect(book.exists).to(beFalse())
        try! book.save()
        expect(book.exists).toNot(beFalse())

        try! book.load()

        expect(book.exists).toNot(beFalse())
        try! book.delete()
        expect(book.exists).to(beFalse())

        let books: [BookModel] = (0 ..< 10).map({ _ in BookModel.fake() })
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