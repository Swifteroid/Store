import Foundation
import Nimble
import Store
import XCTest

internal class ModelObserverTestCase: ModelTestCase
{
    internal func test() {
        let observer: ModelObserver<BookModel> = ModelObserver()
        let model: BookModel
        var expectations: [XCTestExpectation] = []

        model = BookModel(title: "Title", author: "Author", publisher: "Publisher")
        expectations.append(self.expectation(forNotification: ModelObserverNotification.didUpdate.rawValue, object: observer))
        try! model.save()
        expect(observer.models.first?.id).to(equal(model.id))

        model.title = "bar"
        expectations.append(self.expectation(forNotification: ModelObserverNotification.didUpdate.rawValue, object: observer))
        try! model.save()
        expect(observer.models.first?.title).to(equal(model.title))

        model.title = "qux"
        expectations.append(self.expectation(forNotification: ModelObserverNotification.didUpdate.rawValue, object: observer))
        try! model.save()
        expect(observer.models.first?.title).to(equal(model.title))

        self.wait(for: expectations, timeout: 1)
    }
}