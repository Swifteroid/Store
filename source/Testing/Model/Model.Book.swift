import CoreData
import Fakery
import Store

internal class BookModel: Model<NoConfiguration>, BatchableProtocol
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
    override internal func construct(with object: Object, configuration: Model.Configuration? = nil) -> Model {
        return super.update(model: Model(), with: object, configuration: configuration)
    }

    override internal func update(model: Model, with object: Object, configuration: Model.Configuration? = nil) -> Model {
        model.title = object.value(for: Key.title)
        model.author = object.value(for: Key.author)
        model.publisher = object.value(for: Key.publisher)
        return model
    }

    override internal func update(object: Object, with model: Model, configuration: Model.Configuration? = nil) -> Object {
        object.value(set: model.title, for: Key.title)
        object.value(set: model.author, for: Key.author)
        object.value(set: model.publisher, for: Key.publisher)
        return object
    }
}

extension BookBatch
{
    fileprivate struct Key
    {
        fileprivate static let title: String = "title"
        fileprivate static let author: String = "author"
        fileprivate static let publisher: String = "publisher"
    }
}

// MARK: -

extension BookModel
{
    internal static func fake() -> BookModel {
        let faker: Faker = Faker()
        return BookModel(
            title: faker.commerce.productName(),
            author: faker.name.name(),
            publisher: faker.company.name()
        )
    }
}