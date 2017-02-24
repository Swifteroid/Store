import Store
import CoreData

internal class BookModel: Model
{
    internal var title: String!
    internal var author: String!
    internal var publisher: String!

    internal init(id: String? = nil, title: String? = nil, author: String? = nil, publisher: String? = nil) {
        super.init(id: id)
        self.title = title
        self.author = author
        self.publisher = publisher
    }
}

internal class BookModelSet: ModelSet<BookModel, Void>
{
    override internal func update(object: NSManagedObject, with book: BookModel, configuration: Void? = nil) -> NSManagedObject {
        return object.setValues([
            "title": book.title,
            "author": book.author,
            "publisher": book.publisher
        ])
    }

    override internal func construct(with object: NSManagedObject, configuration: Void? = nil) -> BookModel {
        return super.update(model: BookModel(), with: object, configuration: configuration)
    }

    override func update(model book: BookModel, with object: NSManagedObject, configuration: Void? = nil) -> BookModel {
        book.title = object.value(forKey: "title") as! String
        book.author = object.value(forKey: "author") as! String
        book.publisher = object.value(forKey: "publisher") as! String
        return super.update(model: book, with: object, configuration: configuration)
    }
}