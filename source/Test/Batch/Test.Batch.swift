import CoreData
import Store
import Nimble

internal class BatchTestCase: TestCase
{
    internal func test() {
        let batch: Batch = Batch()
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest()
        let configuration: Configuration = Configuration(fetch: FetchConfiguration(limit: 1, offset: 2, sort: [NSSortDescriptor(key: "foo", ascending: true)]))

        expect(request.fetchLimit).to(equal(0))
        expect(request.fetchOffset).to(equal(0))
        expect(request.sortDescriptors).to(beNil())

        batch.prepare(request: request, configuration: configuration)

        expect(request.fetchLimit).to(equal(configuration.fetch!.limit))
        expect(request.fetchOffset).to(equal(configuration.fetch!.offset))
        expect(request.sortDescriptors).to(equal(configuration.fetch!.sort))
    }
}

fileprivate struct Configuration: ModelConfiguration, ModelFetchConfiguration
{
    fileprivate var fetch: FetchConfiguration?
}

fileprivate class Model: Store.InitialisableModel<Configuration>, Batchable
{
    typealias Batch = Store___Test.Batch
}

fileprivate class Batch: Store.AbstractBatch<Model>
{
}