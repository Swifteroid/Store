import Store
import CoreData

internal class UserModel: Model
{
    internal var name: String!
    internal var address: String!
    internal var books: [BookModel]!

    internal init(id: String? = nil, name: String? = nil, address: String? = nil) {
        super.init(id: id)
        self.name = name
        self.address = address
    }
}

internal class UserModelSet: ModelSet<UserModel, Void>
{
    override internal func update(object: NSManagedObject, with user: UserModel, configuration: Void? = nil) -> NSManagedObject {
        return object.setValues([
            "name": user.name,
            "address": user.address
        ])
    }

    override internal func construct(with object: NSManagedObject, configuration: Void? = nil) -> UserModel {
        return super.update(model: UserModel(), with: object, configuration: configuration)
    }

    override func update(model user: UserModel, with object: NSManagedObject, configuration: Void? = nil) -> UserModel {
        user.name = object.value(forKey: "name") as! String
        user.address = object.value(forKey: "address") as! String
        return super.update(model: user, with: object, configuration: configuration)
    }
}