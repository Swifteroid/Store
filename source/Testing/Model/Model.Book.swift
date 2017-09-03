import CoreData
import Fakery
import Store

internal class BookModel: AbstractBatchConstructableModel, Batchable
{
    internal typealias Batch = BookBatch

    internal convenience init(id: Object.Id? = nil, title: String? = nil, publisher: String? = nil, authors: [AuthorModel]? = nil, user: UserModel? = nil) {
        self.init(id: id)

        self.title = title
        self.publisher = publisher

        self.authors = authors ?? []
        self.user = user
    }

    // MARK: -

    internal var title: String!
    internal var publisher: String!

    internal var authors: [AuthorModel] = []
    internal var user: UserModel?
}

internal class BookBatch: AbstractBatch<BookModel, ()>
{
    override internal func update(model: Model, with object: Object, configuration: Configuration? = nil) throws -> Model {
        model.title = object.value(for: Key.title)!
        model.publisher = object.value(for: Key.publisher)!

        model.authors = try object.relationship(for: Key.authors)
        model.user = try object.relationship(for: Key.user)

        return model
    }

    override internal func update(object: Object, with model: Model, configuration: Configuration? = nil) throws -> Object {
        object.value(set: model.title, for: Key.title)
        object.value(set: model.publisher, for: Key.publisher)

        try object.relationship(set: model.authors, for: Key.authors)
        try object.relationship(set: model.user, for: Key.user)

        return object
    }
}

extension BookBatch
{
    fileprivate enum Key: String
    {
        case title
        case authors
        case publisher
        case user
    }
}

// MARK: -

extension BookModel
{
    internal static func fake(authors: [AuthorModel]? = nil, user: UserModel? = nil) -> BookModel {
        let faker: Faker = Faker()
        return BookModel(
            title: faker.commerce.productName(),
            publisher: faker.company.name(),
            authors: authors ?? [try! AuthorModel.fake().save()],
            user: user
        )
    }
}