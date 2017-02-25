import CoreData
import Store

internal class BookModel: Model<BookModelKey, NoConfiguration>, ModelSetElementProtocol
{
    public typealias Set = BookModelSet

    internal var title: String!
    internal var author: String!
    internal var publisher: String!

    internal init(id: String? = nil, title: String? = nil, author: String? = nil, publisher: String? = nil) {
        super.init(id: id)
        self.title = title
        self.author = author
        self.publisher = publisher
    }

    override internal subscript(property: Key) -> Any? {
        get {
            switch property {
                case .author: return self.author
                case .publisher: return self.publisher
                case .title: return self.title
            }
        }
        set {
            switch property {
                case .author:  self.author = newValue as! String
                case .publisher: self.publisher = newValue as! String
                case .title: self.title = newValue as! String
            }
        }
    }
}

internal class BookModelSet: ModelSet<BookModel>
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