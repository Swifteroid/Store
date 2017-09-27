import CoreData
import Fakery
import Store

internal final class AuthorModel: BatchConstructableModel, Batchable
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

internal final class AuthorBatch: Batch<AuthorModel, AuthorConfiguration>
{
    override internal func update(model: Model, with object: Object, configuration: Configuration? = nil) throws -> Model {
        let cfg: Configuration = configuration ?? Configuration.default

        model.firstName = object.value(for: Key.firstName)
        model.lastName = object.value(for: Key.lastName)

        if let cfg = cfg.books { model.books = try object.relationship(for: Key.books, configuration: cfg) }

        return model
    }

    override internal func update(object: Object, with model: Model, configuration: Configuration? = nil) throws -> Object {
        object.value(set: model.firstName, for: Key.firstName)
        object.value(set: model.lastName, for: Key.lastName)

        try object.relationship(set: model.books, for: Key.books)

        return object
    }
}

internal class AuthorConfiguration: BatchRelationshipConfiguration
{
    internal static let `default`: AuthorConfiguration = AuthorConfiguration(books: BookConfiguration(authors: AuthorConfiguration(relationship: [])))

    internal let books: BookConfiguration?
    internal let relationship: RelationshipConfiguration?

    internal init(books: BookConfiguration? = nil, relationship: RelationshipConfiguration? = nil) {
        self.books = books
        self.relationship = relationship
    }
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