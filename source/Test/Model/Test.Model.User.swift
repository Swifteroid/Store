import CoreData
import Foundation
import Nimble
import Store

internal class UserModelTestCase: ModelTestCase
{
    internal func test() {
        let user: UserModel = UserModel.fake()

        expect(user.exists).to(beFalse())
        try! user.save()
        expect(user.exists).toNot(beFalse())

        try! user.load()

        expect(user.exists).toNot(beFalse())
        try! user.delete()
        expect(user.exists).to(beFalse())

        let users: [UserModel] = (0 ..< 10).map({ _ in UserModel.fake() })
        var batch: UserBatch

        batch = UserBatch(models: users)
        try! batch.save()
        expect(batch.models.map({ $0.id })).toNot(allPass(beNil()))

        batch = UserBatch(models: users)
        try! batch.load()
        expect(batch.models).to(haveCount(10))
        expect(batch.models.first?.name).toNot(beNil())
        expect(batch.models.first?.address).toNot(beNil())

        try! batch.delete()
        expect(batch.models).to(beEmpty())

        try! batch.load()
        expect(batch.models).to(beEmpty())
    }
}