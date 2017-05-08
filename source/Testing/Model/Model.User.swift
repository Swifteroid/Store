import CoreData
import Fakery
import Store

internal class UserModel: Model<UserModelKey, NoConfiguration>, BatchableProtocol
{
    internal typealias Batch = UserBatch

    internal var name: String!
    internal var address: String!
    internal var books: [BookModel]!

    internal init(id: String? = nil, name: String? = nil, address: String? = nil) {
        super.init(id: id)
        self.name = name
        self.address = address
    }
}

internal class UserBatch: Batch<UserModel>
{
    override internal func construct(with object: NSManagedObject, configuration: Model.Configuration? = nil) -> Model {
        return super.update(model: UserModel(), with: object, configuration: configuration)
    }

    override internal func update(model: Model, with object: NSManagedObject, configuration: Model.Configuration?) -> Model {
        super.update(model: model, with: object, configuration: configuration)
        model.books = object.relationship(for: "book")
        return model
    }

    override internal func update(object: NSManagedObject, with model: Model, configuration: Model.Configuration?) -> NSManagedObject {
        super.update(object: object, with: model, configuration: configuration)
        try! object.relationship(set: model.books, for: "book")
        return object
    }
}

internal enum UserModelKey: String, ModelKeyProtocol
{
    internal typealias Configuration = NoConfiguration

    case name
    case address

    public static var all: [UserModelKey] {
        return [
            self.name,
            self.address
        ]
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