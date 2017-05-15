import Foundation
import Nimble
import Store
import XCTest

internal class ModelObserverTestCase: ModelTestCase
{
    internal func testObservation() {
        let observer: ModelObserver<BookModel> = ModelObserver()
        let model: BookModel
        var expectations: [XCTestExpectation] = []

        model = BookModel.fake()
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

    /// Checks that fetching rules are correctly applied observed models.

    internal func testFetch() {
        var users: [UserModel] = ["A", "C", "E"].map({ try! UserModel.fake(name: $0).save() }) + ["G", "I"].map({ UserModel.fake(name: $0) })
        let configuration: UserConfiguration = UserConfiguration(fetch: FetchConfiguration(limit: 6, offset: 0, sort: [NSSortDescriptor(key: "name", ascending: false)]))
        let observer: ModelObserver<UserModel> = ModelObserver(models: users, configuration: configuration)

        expect(observer.models).to(equal(users))

        // Manually sort users in accordance with fetch sort configuration. 

        users.sort(by: { !$0.identified && $1.identified || $0.identified && $1.identified && $0.name > $1.name }) // G, I, E, C, A

        // Insert new model and assert correct order.

        users.insert(try! UserModel.fake(name: "D").save(), at: 3) // G, I, E, D, C, A
        expect(observer.models.map({ $0.name })).to(equal(users.map({ $0.name })))

        // Inserting an extra model must result in A getting dropped.

        users.insert(try! UserModel.fake(name: "B").save(), at: 5) // G, I, E, D, C, B, A
        users.remove(at: 6) // G, I, E, D, C, B
        expect(observer.models.map({ $0.name })).to(equal(users.map({ $0.name })))

        // Inserting an extra model that falls outside sort + limit configuration makes no difference.

        try! UserModel.fake(name: "A").save()
        expect(observer.models.map({ $0.name })).to(equal(users.map({ $0.name })))
    }
}