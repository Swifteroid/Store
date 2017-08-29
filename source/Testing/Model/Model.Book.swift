import CoreData
import Fakery
import Store

internal class BookModel: InitialisableModel<NoConfiguration>, Batchable
{
    internal typealias Batch = BookBatch

    internal var title: String!
    internal var author: String!
    internal var publisher: String!

    internal var user: UserModel?

    internal convenience init(id: Object.Id? = nil, title: String? = nil, author: String? = nil, publisher: String? = nil, user: UserModel? = nil) {
        self.init(id: id)

        self.title = title
        self.author = author
        self.publisher = publisher

        self.user = user
    }
}

internal class BookBatch: AbstractBatch<BookModel>
{
    override internal func update(model: Model, with object: Object, configuration: Configuration? = nil) -> Model {
        model.title = object.value(for: Key.title)!
        model.author = object.value(for: Key.author)!
        model.publisher = object.value(for: Key.publisher)!

        model.user = object.relationship(for: Key.user)

        return model
    }

    override internal func update(object: Object, with model: Model, configuration: Configuration? = nil) -> Object {
        object.value(set: model.title, for: Key.title)
        object.value(set: model.author, for: Key.author)
        object.value(set: model.publisher, for: Key.publisher)

        object.value(set: model.user, for: Key.user)

        return object
    }
}

extension BookBatch
{
    fileprivate enum Key: String
    {
        case title
        case author
        case publisher
        case user
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