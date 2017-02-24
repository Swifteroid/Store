import CoreData
import Foundation
import Nimble
import Store

internal class ModelTestCase: TestCase
{
    override internal class func setUp() {
        let storeUrl: URL = Store.url(for: "Store - Test")
        let schemaUrl: URL = Bundle(for: self).url(forResource: "library", withExtension: "momd")!
        try! FileManager.default.removeItem(at: storeUrl)
        Store.default = Store(storeUrl: storeUrl, schemaUrl: schemaUrl, handler: { true })!
    }

    override internal class func tearDown() {
        Store.default = nil
    }

    // MARK: -

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

// MARK: -

private class BookModel: Model
{
    fileprivate var title: String!
    fileprivate var author: String!
    fileprivate var publisher: String!

    fileprivate init(id: String? = nil, title: String? = nil, author: String? = nil, publisher: String? = nil) {
        super.init(id: id)
        self.title = title
        self.author = author
        self.publisher = publisher
    }
}

private class BookModelSet: ModelSet<BookModel, Void>
{
    override fileprivate func update(object: NSManagedObject, with model: BookModel, configuration: Void? = nil) -> NSManagedObject {
        return object.setValues([
            "title": model.title,
            "author": model.author,
            "publisher": model.publisher
        ])
    }

    override fileprivate func construct(with object: NSManagedObject, configuration: Void? = nil) -> BookModel {
        return super.update(model: BookModel(), with: object, configuration: configuration)
    }

    override func update(model: BookModel, with object: NSManagedObject, configuration: Void? = nil) -> BookModel {
        model.title = object.value(forKey: "title") as! String
        model.author = object.value(forKey: "author") as! String
        model.publisher = object.value(forKey: "publisher") as! String
        return super.update(model: model, with: object, configuration: configuration)
    }
}