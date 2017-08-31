import Foundation
import Nimble
import Store

internal class BookModelTestCase: ModelTestCase
{
    internal func test() {
        self.test((0 ..< 10).map({ _ in BookModel.fake() }), {
            expect($0.title).toNot(beNil())
            expect($0.publisher).toNot(beNil())
            expect($0.authors).toNot(beEmpty())
        })
    }
}