import CoreData
import Foundation
import Nimble
import Store

internal class UserModelTestCase: ModelTestCase
{
    internal func test() {
        let users: [UserModel] = Array(0 ..< 10).map({ UserModel(name: "Name \($0)", address: "Address \($0)") })
        var userSet: UserModelSet

        userSet = UserModelSet(models: users)
        try! userSet.save()
        expect(userSet.models.map({ $0.id })).toNot(allPass(beNil()))

        userSet = UserModelSet(models: users)
        try! userSet.load()
        expect(userSet.models).to(haveCount(10))

        try! userSet.delete()
        expect(userSet.models).to(beEmpty())

        try! userSet.load()
        expect(userSet.models).to(beEmpty())
    }
}