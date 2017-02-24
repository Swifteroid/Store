import CoreData
import Foundation
import Nimble
import Store

internal class BookModelTestCase: ModelTestCase
{
    internal func test() {
        let books: [BookModel] = Array(0 ..< 10).map({ BookModel(title: "Title \($0)", author: "Author \($0)", publisher: "Publisher \($0)") })
        let bookSet: BookModelSet = BookModelSet(models: books)
        try! bookSet.save()

        bookSet.models = []
        try! bookSet.load()
        expect(bookSet.models).to(haveCount(10))

        try! bookSet.delete()
        expect(bookSet.models).to(beEmpty())

        try! bookSet.load()
        expect(bookSet.models).to(beEmpty())
    }
}