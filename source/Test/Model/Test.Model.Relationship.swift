import CoreData
import Foundation
import Nimble
import Store

internal class ModelRelationshipTestCase: ModelTestCase
{
    internal func testRelationship() {
        let books: [BookModel] = (0 ..< 5).map({ _ in try! BookModel.fake().save() })
        let titles = equal(books.map({ $0.title }).sorted())

        var userA: UserModel = UserModel.fake()
        var userB: UserModel = UserModel.fake()

        // Assign books to the first user, reload it and confirm they got saved. Ensure book user
        // is identical to the user owning the book, i.e., confirm caching works.

        userA.books = books
        try! userA.save()

        userA = try! UserModel(id: userA.id).load()
        expect(userA.books.map({ $0.title }).sorted()).to(titles)
        expect(userA.books.first?.user).to(beIdenticalTo(userA))

        // Reassign books to the second user…

        userB.books = books
        try! userB.save()

        userB = try! UserModel(id: userB.id).load()
        expect(userB.books.map({ $0.title }).sorted()).to(titles)
        expect(userB.books.first?.user).to(beIdenticalTo(userB))

        // Now load the first user and confirm it has no books.

        try! userA.load()
        expect(userA.books).to(beEmpty())
    }

    internal func testRelationshipOrder() {
        let authors: [AuthorModel] = (0 ..< 25).map({ _ in try! AuthorModel.fake().save() })
        var book: BookModel = try! BookModel.fake(authors: authors).save()

        book = try! BookModel(id: book.id).load()
        expect(book.authors.map({ $0.id })).to(equal(authors.map({ $0.id })))
    }

    internal func testCaching() {
        let books: [BookModel] = (0 ..< 10).map({ _ in try! BookModel.fake().save() })
        let _: [UserModel] = (0 ..< 10).map({ try! UserModel.fake(books: Array(books[max(0, $0 - 2) ..< min(books.count, $0 + 2)])).save() })

        try! BookBatch().load()
        try! UserBatch().load()
    }

    internal func testConfiguration() {

        // Consider we have 3 authors and 2 books, each book has 2 authors – 1 unique authors and 1 shared. Loading first book without
        // configuration will result in 1 shared author pulling 2 books, which will also pull another author, which is not the desired
        // outcome in most cases. With configuration we shall end up with only 1 book and 4 referenced authors.

        let authors: [AuthorModel] = (0 ..< 3).map({ _ in try! AuthorModel.fake().save() })
        let books: [BookModel] = [
            try! BookModel.fake(authors: Array(authors[0 ..< authors.count - 1])).save(),
            try! BookModel.fake(authors: Array(authors[0 + 1 ..< authors.count])).save()
        ]

        var book: BookModel

        book = try! BookModel(id: books[0].id).load(configuration: BookConfiguration(authors: AuthorConfiguration(books: BookConfiguration(authors: AuthorConfiguration(books: BookConfiguration())))))
        expect(book.authors).to(haveCount(2))
        expect(book.authors[0].books).to(haveCount(1))
        expect(book.authors[1].books).to(haveCount(2))
        expect(book.authors[1].books[0]).to(beIdenticalTo(book))
        expect(book.authors[1].books[1]).toNot(beIdenticalTo(book))
        expect(book.authors[1].books[1].authors[1].books).to(haveCount(1))
        expect(book.authors[1].books[1].authors[1].books[0]).toNot(beIdenticalTo(book))

        book = try! BookModel(id: books[0].id).load(configuration: BookConfiguration(authors: AuthorConfiguration(books: BookConfiguration(relationship: []))))
        expect(book.authors).to(haveCount(2))
        expect(book.authors[0].books).to(haveCount(1))
        expect(book.authors[1].books).to(haveCount(1))
        expect(book.authors[1].books[0]).to(beIdenticalTo(book))
    }
}