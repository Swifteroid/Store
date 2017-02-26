import CoreData
import Foundation
import Nimble
import Store

internal class UserModelTestCase: ModelTestCase
{
    internal func test() {
        let users: [UserModel] = Array(0 ..< 10).map({ UserModel(name: "Name \($0)", address: "Address \($0)") })
        var batch: UserBatch

        batch = UserBatch(models: users)
        try! batch.save()
        expect(batch.models.map({ $0.id })).toNot(allPass(beNil()))

        batch = UserBatch(models: users)
        try! batch.load()
        expect(batch.models).to(haveCount(10))

        try! batch.delete()
        expect(batch.models).to(beEmpty())

        try! batch.load()
        expect(batch.models).to(beEmpty())
    }
}