import CoreData

public typealias Context = NSManagedObjectContext

extension Context
{
    public convenience init(coordinator: NSPersistentStoreCoordinator, concurrency: NSManagedObjectContextConcurrencyType) {
        self.init(concurrencyType: concurrency)
        self.persistentStoreCoordinator = coordinator
    }

    open func existingObject<Model:ModelProtocol>(with model: Model) throws -> Object? {
        if let modelId: String = model.id, let url: URL = URL(string: modelId), let objectId: NSManagedObjectID = self.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) {
            return try self.existingObject(with: objectId)
        } else {
            return nil
        }
    }
}