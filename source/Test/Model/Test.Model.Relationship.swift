import CoreData
import Foundation
import Nimble
import Store

internal class ModelRelationshipTestCase: ModelTestCase
{
    internal func testRelationships() {
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

    internal func testCaching() {
        let books: [BookModel] = (0 ..< 10).map({ _ in try! BookModel.fake().save() })
        let _: [UserModel] = (0 ..< 10).map({ try! UserModel.fake(books: Array(books[max(0, $0 - 2) ..< min(books.count, $0 + 2)])).save() })

        try! BookBatch().load()
        try! UserBatch().load()
    }
}