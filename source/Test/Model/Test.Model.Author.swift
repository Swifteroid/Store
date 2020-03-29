import Foundation
import Nimble
import Store

internal class AuthorModelTestCase: ModelTestCase {
    internal func test() {
        self.test((0 ..< 10).map({ _ in AuthorModel.fake() }), {
            expect($0.firstName).toNot(beNil())
            expect($0.lastName).toNot(beNil())
        })
    }
}
