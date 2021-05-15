import CoreData
import Store
import Nimble

internal class BatchTestCase: TestCase {
    internal func test() {
        let batch: Batch = Batch()
        var request: NSFetchRequest<NSManagedObject> = NSFetchRequest()
        let configuration: Configuration = Configuration(request: Request.Configuration(limit: 1, offset: 2, sort: [NSSortDescriptor(key: "foo", ascending: true)]))

        expect(request.fetchLimit).to(equal(0))
        expect(request.fetchOffset).to(equal(0))
        expect(request.sortDescriptors).to(beNil())

        request = batch.prepare(request: request, configuration: configuration)

        expect(request.fetchLimit).to(equal(configuration.request!.limit))
        expect(request.fetchOffset).to(equal(configuration.request!.offset))
        expect(request.sortDescriptors).to(equal(configuration.request!.sort))
    }
}

fileprivate struct Configuration: BatchRequestConfiguration {
    fileprivate var request: Request.Configuration?
}

fileprivate class Model: BatchConstructableModel, Batchable {
    typealias Batch = Store_Test.Batch

    public var exists: Bool {
        (Batch(models: []) as Batch).exist(models: [self])
    }
}

fileprivate class Batch: Store.Batch<Model, Configuration> {
}
