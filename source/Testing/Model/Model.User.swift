import CoreData
import Fakery
import Store

internal final class UserModel: BatchConstructableModel, Batchable {
    internal typealias Batch = UserBatch

    internal convenience init(id: Object.Id? = nil, name: String? = nil, address: String? = nil, books: [BookModel]? = nil) {
        self.init(id: id)

        self.name = name
        self.address = address

        self.books = books ?? []
    }

    // MARK: -

    internal var name: String!
    internal var address: String!

    internal var books: [BookModel] = []
}

internal final class UserBatch: Batch<UserModel, UserConfiguration> {
    override internal func update(model: Model, with object: Object, configuration: Configuration? = nil) throws -> Model {
        model.name = object.value(for: Key.name)
        model.address = object.value(for: Key.address)

        model.books = try object.relationship(for: Key.books)

        return model
    }

    override internal func update(object: Object, with model: Model, configuration: Configuration? = nil) throws -> Object {
        object.value(set: model.name, for: Key.name)
        object.value(set: model.address, for: Key.address)

        try object.relationship(set: model.books, for: Key.books)

        return object
    }
}

internal struct UserConfiguration: BatchRequestConfiguration {
    internal var request: Request.Configuration?
}

extension UserBatch {
    fileprivate enum Key: String {
        case name
        case address
        case books
    }
}

// MARK: -

extension UserModel {
    internal static func fake(name: String? = nil, books: [BookModel]? = nil) -> UserModel {
        let faker: Faker = Faker()
        return UserModel(
            name: name ?? faker.name.name(),
            address: faker.address.streetAddress(includeSecondary: true),
            books: books
        )
    }
}

extension UserModel: CustomStringConvertible {
    public var description: String {
        "\(type(of: self))(name: \(self.name ?? ""))"
    }
}
