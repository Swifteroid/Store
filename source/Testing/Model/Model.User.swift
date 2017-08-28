import CoreData
import Fakery
import Store

internal class UserModel: InitialisableModel<UserConfiguration>, BatchableProtocol
{
    internal typealias Batch = UserBatch

    internal var name: String!
    internal var address: String!

    internal var books: [BookModel] = []

    internal convenience init(id: Object.Id? = nil, name: String? = nil, address: String? = nil, books: [BookModel]? = nil) {
        self.init(id: id)

        self.name = name
        self.address = address

        self.books = books ?? []
    }
}

internal class UserBatch: Batch<UserModel>
{
    override internal func update(model: Model, with object: Object, configuration: Configuration? = nil) -> Model {
        model.name = object.value(for: Key.name)
        model.address = object.value(for: Key.address)
        model.books = object.relationship(for: Key.books)
        return model
    }

    override internal func update(object: Object, with model: Model, configuration: Configuration? = nil) -> Object {
        object.value(set: model.name, for: Key.name)
        object.value(set: model.address, for: Key.address)
        try! object.relationship(set: model.books, for: Key.books)
        return object
    }
}

internal struct UserConfiguration: ModelConfigurationProtocol, ModelFetchConfigurationProtocol
{
    internal var fetch: FetchConfiguration?
}

extension UserBatch
{
    fileprivate struct Key
    {
        fileprivate static let name: String = "name"
        fileprivate static let address: String = "address"
        fileprivate static let books: String = "books"
    }
}

// MARK: -

extension UserModel
{
    internal static func fake(name: String? = nil) -> UserModel {
        let faker: Faker = Faker()
        return UserModel(
            name: name ?? faker.name.name(),
            address: faker.address.streetAddress(includeSecondary: true)
        )
    }
}

extension UserModel: CustomStringConvertible
{
    public var description: String {
        return "\(type(of: self))(name: \(self.name ?? ""))"
    }
}