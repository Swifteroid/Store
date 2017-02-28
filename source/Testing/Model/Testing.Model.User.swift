import CoreData
import Store

internal class UserModel: Model<UserModelKey, NoConfiguration>, BatchableProtocol
{
    internal typealias Batch = UserBatch

    internal var name: String!
    internal var address: String!

    internal init(id: String? = nil, name: String? = nil, address: String? = nil) {
        super.init(id: id)
        self.name = name
        self.address = address
    }
}

internal class UserBatch: Batch<UserModel>
{
    override internal func construct(with object: NSManagedObject, configuration: Model.Configuration? = nil) -> UserModel {
        return super.update(model: UserModel(), with: object, configuration: configuration)
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