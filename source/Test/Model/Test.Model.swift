import Foundation
import Nimble
import Store

internal class ModelTestCase: TestCase, PersistentStoreTestCase {
    internal static let schemaUrl: URL = PathUtility.librarySchemaUrl

    internal func test<Model: Batchable>(_ models: [Model], _ test: (Model) -> Void) where Model.Batch.Model == Model, Model.Batch.Configuration == Model.Configuration {
        var models: [Model] = models
        var batch: Model.Batch

        // Test single model first.

        self.test(models.removeFirst())

        batch = Model.Batch(models: models)
        try! batch.save(configuration: nil)
        expect(batch.models.map({ $0.id })).toNot(allPass(beNil()))

        batch = Model.Batch()
        try! batch.load(configuration: nil)
        expect(batch.models).to(haveCount(models.count))

        test(batch.models.first!)

        try! batch.delete(configuration: nil)
        expect(batch.models).to(beEmpty())

        try! batch.load(configuration: nil)
        expect(batch.models).to(beEmpty())
    }

    /// Take a single model and ensure it passes the synthetic test.

    private func test<Model: Batchable>(_ model: Model) where Model.Batch.Model == Model, Model.Batch.Configuration == Model.Configuration {
        expect(model.exists).to(beFalse())
        try! model.save()
        expect(model.exists).toNot(beFalse())

        try! model.load()

        expect(model.exists).toNot(beFalse())
        try! model.delete()
        expect(model.exists).to(beFalse())
    }
}
