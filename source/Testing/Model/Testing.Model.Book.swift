import CoreData
import Store

internal class BookModel: Model<BookModelKey, NoConfiguration>, BatchableProtocol
{
    public typealias Batch = BookBatch

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

internal class BookBatch: Batch<BookModel>
{
    override internal func construct(with object: NSManagedObject, configuration: Model.Configuration? = nil) -> BookModel {
        return super.update(model: BookModel(), with: object, configuration: configuration)
    }
}

internal enum BookModelKey: String, ModelKeyProtocol
{
    internal typealias Configuration = NoConfiguration

    case author
    case publisher
    case title

    public static var all: [BookModelKey] {
        return [
            self.author,
            self.publisher,
            self.title
        ]
    }
}