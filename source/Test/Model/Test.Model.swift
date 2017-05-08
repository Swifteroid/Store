import CoreData
import Foundation
import Nimble
import Store

internal class ModelTestCase: TestCase
{
    override internal class func setUp() {
        let storeUrl: URL = Coordinator.url(for: "Store - Test")
        let schemaUrl: URL = PathUtility.librarySchemaUrl
        try! FileManager.default.removeItem(at: storeUrl)
        Coordinator.default = Coordinator(store: storeUrl, schema: schemaUrl, handler: { true })!
    }

    override internal class func tearDown() {
        if let coordinator: Coordinator = Coordinator.default {
            for store: NSPersistentStore in coordinator.persistentStores {
                try! coordinator.remove(store)
            }

            Coordinator.default = nil
        }
    }

    // MARK: -

    internal func testRelationships() {
        let books: [BookModel] = [try! BookModel.fake().save(), try! BookModel.fake().save()]
        let bookIds = equal(books.map({ $0.id! }).sorted())

        var userA: UserModel = UserModel.fake()
        var userB: UserModel = UserModel.fake()

        // Assign books to the first user, reload it and confirm they got saved.

        userA.books = books
        try! userA.save()

        userA = try! UserModel(id: userA.id).load()
        expect(userA.books.map({ $0.id! }).sorted()).to(bookIds)

        // Reassign books to the second user…

        userB.books = books
        try! userB.save()

        userB = try! UserModel(id: userB.id).load()
        expect(userB.books.map({ $0.id! }).sorted()).to(bookIds)

        // Now load the first user and confirm it has no books.

        try! userA.load()
        expect(userA.books).to(beEmpty())
    }
}