import CoreData
import Foundation
import Nimble
import Store

internal class UserModelTestCase: ModelTestCase
{
    internal func test() {
        let users: [UserModel] = Array(0 ..< 10).map({ UserModel(name: "Name \($0)", address: "Address \($0)") })
        let userSet: UserModelSet = UserModelSet(models: users)
        try! userSet.save()

        userSet.models = []
        try! userSet.load()
        expect(userSet.models).to(haveCount(10))

        try! userSet.delete()
        expect(userSet.models).to(beEmpty())

        try! userSet.load()
        expect(userSet.models).to(beEmpty())
    }
}