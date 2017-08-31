import Foundation
import Nimble
import Store

internal class UserModelTestCase: ModelTestCase
{
    internal func test() {
        self.test((0 ..< 10).map({ _ in UserModel.fake() }), {
            expect($0.name).toNot(beNil())
            expect($0.address).toNot(beNil())
        })
    }
}