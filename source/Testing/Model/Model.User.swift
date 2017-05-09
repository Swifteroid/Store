import CoreData
import Fakery
import Store

internal class UserModel: Model<NoConfiguration>, BatchableProtocol
{
    internal typealias Batch = UserBatch

    internal var name: String!
    internal var address: String!
    internal var books: [BookModel] = []

    internal init(id: String? = nil, name: String? = nil, address: String? = nil) {
        super.init(id: id)
        self.name = name
        self.address = address
    }
}

internal class UserBatch: Batch<UserModel>
{
    override internal func construct(with object: NSManagedObject, configuration: Model.Configuration? = nil) -> Model {
        return self.update(model: UserModel(), with: object, configuration: configuration)
    }

    override internal func update(model: Model, with object: NSManagedObject, configuration: Model.Configuration?) -> Model {
        model.name = object.value(for: Key.name)
        model.address = object.value(for: Key.address)
        model.books = object.relationship(for: Key.book)
        return model
    }

    override internal func update(object: NSManagedObject, with model: Model, configuration: Model.Configuration?) -> NSManagedObject {
        object.value(set: model.name, for: Key.name)
        object.value(set: model.address, for: Key.address)
        try! object.relationship(set: model.books, for: Key.book)
        return object
    }
}

extension UserBatch
{
    fileprivate struct Key
    {
        fileprivate static let name: String = "name"
        fileprivate static let address: String = "address"
        fileprivate static let book: String = "book"
    }
}

// MARK: -

extension UserModel
{
    internal static func fake() -> UserModel {
        let faker: Faker = Faker()
        return UserModel(
            name: faker.name.name(),
            address: faker.address.streetAddress(includeSecondary: true)
        )
    }
}