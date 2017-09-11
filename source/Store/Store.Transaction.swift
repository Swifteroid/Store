import CoreData

/// Todo: while this works and it's cool, the biggest issue seems to be the number of calls we make to retrieve objects. Perhaps a better
/// todo: approach would be to introduce `Transactional` model protocol and store objects there until transaction is complete. 

internal class Transaction
{
    internal fileprivate(set) static var current: Transaction?

    // MARK: -

    internal init(coordinator: Coordinator? = nil, context: Context? = nil) {
        self.context = context ?? CacheableContext(coordinator: coordinator ?? Coordinator.default, concurrency: .privateQueueConcurrencyType)
    }

    // MARK: -

    internal let context: Context

    // MARK: -

    // A collection of models which require their ids updated after committing the transaction – this copies logic
    // implemented by batch during saving.

    private var objects: [AnyHashable: Object] = [:]

    internal func save<Model:Store.Model & Hashable>(model: Model, object: Object) {
        self.objects[AnyHashable(model)] = object
    }

    internal func save<Model:Store.Model & Hashable>(models: [Model: Object]) {
        for (model, object) in models {
            self.objects[AnyHashable(model)] = object
        }
    }

    internal func object<Model:Store.Model & Hashable>(for model: Model) -> Object? {
        return self.objects[AnyHashable(model)]
    }

    // MARK: -

    fileprivate func begin() throws {
        type(of: self).current = self
    }

    fileprivate func end() throws {
        try self.context.save()

        for (model, object) in self.objects {
            (model.base as! Model).id = object.objectID
        }

        type(of: self).current = nil
    }
}

public func transaction(coordinator: Coordinator? = nil, context: Context? = nil, _ block: () throws -> ()) throws {
    if let _ = Transaction.current { throw Transaction.Error.nestedTransaction }
    let transaction: Transaction = Transaction(coordinator: coordinator, context: context)

    try transaction.begin()
    try block()
    try transaction.end()
}

extension Transaction
{
    internal enum Error: Swift.Error
    {

        /// We don't support nested transactions at the moment.
        case nestedTransaction
    }
}