import CoreData
import Store
import Fakery

internal class MigrationData_1_0_1: MigrationData
{
    override internal func setUp(coordinator: Coordinator, context: Context) {
        let bookEntity: Entity = coordinator.schema.entity(for: "Book")!
        var books: [Object] = []
        let faker: Faker = Faker()

        books += Array(0 ..< 5).map({ _ in
            Object(entity: bookEntity, insertInto: context).value(set: [
                "title": faker.commerce.productName(),
                "author": faker.name.name(),
                "publisher": faker.company.name()
            ])
        })

        try! context.save()
    }
}