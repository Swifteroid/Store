import CoreData

public typealias Context = NSManagedObjectContext

extension Context
{
    public convenience init(coordinator: Coordinator, concurrency: NSManagedObjectContextConcurrencyType) {
        self.init(concurrencyType: concurrency)
        self.coordinator = coordinator
    }

    open func existingObject<Model:ModelProtocol>(with model: Model) throws -> Object? {
        if let id: Object.Id = model.id {
            return try self.existingObject(with: id)
        } else {
            return nil
        }
    }

    open var coordinator: Coordinator? {
        get { return self.persistentStoreCoordinator }
        set { self.persistentStoreCoordinator = newValue }
    }
}