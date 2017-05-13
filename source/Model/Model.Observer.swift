import CoreData
import Foundation

public protocol ModelObserverProtocol: class
{
    associatedtype Model: BatchableProtocol
}

open class ModelObserver<ModelType:BatchableProtocol>: ModelObserverProtocol
{
    public typealias Model = ModelType

    public init() {
        self.observer = NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextDidSave, object: nil, queue: OperationQueue.current, using: { [weak self] in self?.handleContextNotification($0) })
    }

    public convenience init(models: [Model]) {
        self.init()
        self.models = models
    }

    deinit {
        if let observer: Any = self.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: -

    private var observer: Any?

    open var models: [Model] = []

    // MARK: -

    open func update(batch: Model.Batch, notification: Notification) {
        try! batch.load(configuration: nil)
        self.models = batch.models as! [Model]
    }

    // MARK: -

    private func handleContextNotification(_ notification: Notification) {
        let batch: Model.Batch = Model.Batch(models: self.models as! [Model.Batch.Model])
        self.update(batch: batch, notification: notification)

        // Todo: this should be done smarter, maybe require update to return new status?

        NotificationCenter.default.post(name: ModelObserverNotification.didUpdate, object: self)
    }
}

// MARK: -

public struct ModelObserverNotification
{
    public static let didUpdate: Notification.Name = Notification.Name("ModelObserverDidUpdateNotification")
}