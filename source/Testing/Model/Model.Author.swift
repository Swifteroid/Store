import CoreData
import Fakery
import Store

internal class AuthorModel: InitialisableModel<AuthorConfiguration>, Batchable
{
    internal typealias Batch = AuthorBatch

    internal convenience init(id: Object.Id? = nil, firstName: String? = nil, lastName: String? = nil, books: [BookModel]? = nil) {
        self.init(id: id)

        self.firstName = firstName
        self.lastName = lastName

        self.books = books ?? []
    }

    // MARK: -

    internal var firstName: String!
    internal var lastName: String!

    internal var books: [BookModel] = []

}

internal class AuthorBatch: AbstractBatch<AuthorModel>
{
    override internal func update(model: Model, with object: Object, configuration: Configuration? = nil) -> Model {
        model.firstName = object.value(for: Key.firstName)
        model.lastName = object.value(for: Key.lastName)
        model.books = object.relationship(for: Key.books)
        return model
    }

    override internal func update(object: Object, with model: Model, configuration: Configuration? = nil) -> Object {
        object.value(set: model.firstName, for: Key.firstName)
        object.value(set: model.lastName, for: Key.lastName)
        try! object.relationship(set: model.books, for: Key.books)
        return object
    }
}

internal struct AuthorConfiguration: ModelConfiguration, ModelFetchConfiguration
{
    internal var fetch: FetchConfiguration?
}

extension AuthorBatch
{
    fileprivate enum Key: String
    {
        case firstName
        case lastName
        case books
    }
}

// MARK: -

extension AuthorModel
{
    internal static func fake(books: [BookModel]? = nil) -> AuthorModel {
        let faker: Faker = Faker()
        return AuthorModel(
            firstName: faker.name.firstName(),
            lastName: faker.name.lastName(),
            books: books
        )
    }
}

extension AuthorModel: CustomStringConvertible
{
    public var description: String {
        return "\(type(of: self))(firstName: \(self.firstName ?? ""), lastName: \(self.lastName ?? ""))"
    }
}