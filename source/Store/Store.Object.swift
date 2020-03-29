import CoreData

public typealias Object = NSManagedObject

extension Object {
    public typealias Id = NSManagedObjectID
}

// MARK: -

// Provides access to common set methods.

internal protocol RelationshipSet {
    func removeAllObjects()
    func addObjects(from array: [Any])
}

extension NSMutableSet: RelationshipSet {
}

extension NSMutableOrderedSet: RelationshipSet {
}

// MARK: kvc

extension Object {
    @discardableResult public func value<Value>(set value: Value?, for key: String, transform: ((Value) -> Any?)? = nil) -> Self {
        if let value: Value = value, let transform: (Value) -> Any? = transform {
            self.setValue(transform(value), forKey: key)
        } else {
            self.setValue(value, forKey: key)
        }
        return self
    }

    @discardableResult public func value(set value: [String: Any?]) -> Self {
        for (key, value) in value {
            self.setValue(value, forKey: key)
        }
        return self
    }

    public func value<Value>(for key: String) -> Value? {
        self.value(forKey: key) as! Value?
    }

    public func value<Raw, Transformed>(for key: String, transform: ((Raw) -> Transformed?)?) -> Transformed? {
        let value: Raw? = self.value(forKey: key) as! Raw?

        if let value: Raw = value, let transform: (Raw) -> Transformed? = transform {
            return transform(value)
        } else {
            return value as! Transformed?
        }
    }
}

// MARK: RawRepresentable

extension Object {
    @discardableResult public func value<Key: RawRepresentable, Value>(set value: Value?, for key: Key, transform: ((Value) -> Any?)? = nil) -> Self where Key.RawValue == String {
        if let value: Value = value, let transform: (Value) -> Any? = transform {
            self.setValue(transform(value), forKey: key.rawValue)
        } else {
            self.setValue(value, forKey: key.rawValue)
        }
        return self
    }

    @discardableResult public func value<Key: RawRepresentable>(set value: [Key: Any?]) -> Self where Key.RawValue == String {
        for (key, value) in value {
            self.setValue(value, forKey: key.rawValue)
        }
        return self
    }

    public func value<Key: RawRepresentable, Value>(for key: Key) -> Value? where Key.RawValue == String {
        self.value(forKey: key.rawValue) as! Value?
    }

    public func value<Key: RawRepresentable, Raw, Transformed>(for key: Key, transform: ((Raw) -> Transformed?)?) -> Transformed? where Key.RawValue == String {
        let value: Raw? = self.value(forKey: key.rawValue) as! Raw?

        if let value: Raw = value, let transform: (Raw) -> Transformed? = transform {
            return transform(value)
        } else {
            return value as! Transformed?
        }
    }
}

// MARK: relationship

extension Object {
    @nonobjc open func relationship(for name: String) -> [Object] {
        self.mutableSetValue(forKey: name).allObjects as! [Object]
    }

    @nonobjc open func relationship(for name: String) -> Object? {
        self.value(forKey: name) as! Object?
    }

    // MARK: -

    /// Returns related models using model construction method in batch derived from specified batchable protocol.
    ///
    /// - parameter construct: construct model instead of using cache.
    /// - parameter update: update cached model.

    open func relationship<Model: Batchable>(for name: String, configuration: Model.Configuration? = nil, cache: ModelCache? = nil, construct: Bool? = nil, update: Bool? = nil) throws -> [Model] where Model.Batch.Model == Model, Model.Batch.Configuration == Model.Configuration {
        guard let relationship = self.entity.relationshipsByName[name] else { throw RelationshipError.undefined }

        // Todo: find a way to not create new batch every single time. Perhaps move this into entity?
        // Todo: since 10.11 we can use objectIDs(forRelationshipNamed: …), should we?

        let cache: ModelCache? = cache ?? (self.managedObjectContext as? CacheableContext)?.cache
        let construct: Bool? = construct ?? (configuration as? BatchRelationshipConfiguration)?.relationship?.contains(.construct)
        let update: Bool? = update ?? (configuration as? BatchRelationshipConfiguration)?.relationship?.contains(.update)
        let batch: Model.Batch = Model.Batch(models: [])
        var models: [Model] = []

        for object in relationship.isOrdered ? self.mutableOrderedSetValue(forKey: name).array : self.mutableSetValue(forKey: name).allObjects {

            // This is un-elegant as fuck, but the fastest way to iterate over set – tried using both native `NSFastEnumerationIterator`
            // and casted array…

            let object: Object = object as! Object

            if construct != true, let model: Model = cache?.model(with: object.objectID) {
                models.append(update == true ? try batch.update(model: model, with: object, configuration: configuration) : model)
            } else if construct != false {
                let model: Model = try batch.construct(with: object, configuration: configuration, cache: cache)
                models.append(model)
                cache?.add(model: model)
            }
        }

        return models
    }

    /// Returns related model either constructing one or using existing from cache with matching id. In many cases models
    /// are hierarchically interrelated and reference each other, thus, to avoid `child` model from constructing `parent`
    /// we can pass a list of existing parents, which will be reused.
    ///
    /// - parameter construct: construct model instead of using cache.
    /// - parameter update: update cached model.

    open func relationship<Model: Batchable>(for name: String, configuration: Model.Configuration? = nil, cache: ModelCache? = nil, construct: Bool? = nil, update: Bool? = nil) throws -> Model? where Model.Batch.Model == Model, Model.Batch.Configuration == Model.Configuration {
        guard let object: Object = self.value(for: name) else { return nil }
        let cache: ModelCache? = cache ?? (self.managedObjectContext as? CacheableContext)?.cache
        let construct: Bool? = construct ?? (configuration as? BatchRelationshipConfiguration)?.relationship?.contains(.construct)
        let update: Bool? = update ?? (configuration as? BatchRelationshipConfiguration)?.relationship?.contains(.update)

        // Todo: find a way to not create new batch every single time. Perhaps move this into entity?

        if construct != true, let model: Model = cache?.model(with: object.objectID) {
            return update == true ? (try Model.Batch(models: []).update(model: model, with: object, configuration: configuration)) : model
        } else if construct != false {
            let model: Model = try Model.Batch(models: []).construct(with: object, configuration: configuration, cache: cache)
            cache?.add(model: model)
            return model
        }

        return nil
    }

    // MARK: -

    /// Sets new relationship objects replacing all existing ones.

    @nonobjc open func relationship(set objects: [Object], for name: String) throws {
        guard let relationship = self.entity.relationshipsByName[name] else { throw RelationshipError.undefined }
        let set: RelationshipSet = relationship.isOrdered ? self.mutableOrderedSetValue(forKey: name) : self.mutableSetValue(forKey: name)
        set.removeAllObjects()
        set.addObjects(from: objects)
    }

    @nonobjc open func relationship(set object: Object?, for name: String) {
        self.value(set: object, for: name)
    }

    // MARK: -

    /// Sets new relationship models.

    open func relationship<Model: ModelProtocol & Hashable>(set models: [Model], for name: String) throws {
        let transaction: Transaction? = Transaction.current
        guard let context: Context = transaction?.context ?? self.managedObjectContext else { throw RelationshipError.noContext }
        var objects: [Object] = []

        for model in models {
            if let object: Object = try transaction?.object(for: model) ?? context.existingObject(with: model) {
                objects.append(object)
            } else {
                throw RelationshipError.noObject
            }
        }

        try self.relationship(set: objects, for: name)
    }

    open func relationship<Model: ModelProtocol & Hashable>(set model: Model?, for name: String) throws {
        if let model: Model = model {
            let transaction: Transaction? = Transaction.current
            guard let context: Context = transaction?.context ?? self.managedObjectContext else { throw RelationshipError.noContext }

            if let object: Object = try transaction?.object(for: model) ?? context.existingObject(with: model) {
                self.relationship(set: object, for: name)
            } else {
                throw RelationshipError.noObject
            }
        } else {
            self.relationship(set: nil, for: name)
        }
    }
}

// MARK: RawRepresentable

extension Object {
    @nonobjc open func relationship<Name: RawRepresentable>(for name: Name) -> [Object] where Name.RawValue == String {
        self.mutableSetValue(forKey: name.rawValue).allObjects as! [Object]
    }

    @nonobjc open func relationship<Name: RawRepresentable>(for name: Name) -> Object? where Name.RawValue == String {
        self.value(forKey: name.rawValue) as! Object?
    }

    open func relationship<Name: RawRepresentable, Model: Batchable>(for name: Name, configuration: Model.Configuration? = nil, cache: ModelCache? = nil, construct: Bool? = nil, update: Bool? = nil) throws -> [Model] where Name.RawValue == String, Model.Batch.Model == Model, Model.Batch.Configuration == Model.Configuration {
        try self.relationship(for: name.rawValue, configuration: configuration, cache: cache, construct: construct, update: update)
    }

    open func relationship<Name: RawRepresentable, Model: Batchable>(for name: Name, configuration: Model.Configuration? = nil, cache: ModelCache? = nil, construct: Bool? = nil, update: Bool? = nil) throws -> Model? where Name.RawValue == String, Model.Batch.Model == Model, Model.Batch.Configuration == Model.Configuration {
        try self.relationship(for: name.rawValue, configuration: configuration, cache: cache, construct: construct, update: update)
    }

    @nonobjc open func relationship<Name: RawRepresentable>(set objects: [Object], for name: Name) throws where Name.RawValue == String {
        try self.relationship(set: objects, for: name.rawValue)
    }

    @nonobjc open func relationship<Name: RawRepresentable>(set object: Object?, for name: Name) where Name.RawValue == String {
        self.relationship(set: object, for: name.rawValue)
    }

    open func relationship<Name: RawRepresentable, Model: ModelProtocol & Hashable>(set models: [Model], for name: Name) throws where Name.RawValue == String {
        try self.relationship(set: models, for: name.rawValue)
    }

    open func relationship<Name: RawRepresentable, Model: ModelProtocol & Hashable>(set model: Model?, for name: Name) throws where Name.RawValue == String {
        try self.relationship(set: model, for: name.rawValue)
    }
}

// MARK: -

extension Object {
    public enum RelationshipError: Error {

        /// Managed object upon which a relationship is being updated has no context making it impossible to retrieve model
        /// managed objects.
        case noContext

        /// Cannot retrieve model's managed object, it's probably not saved or got deleted.
        case noObject

        /// The specified relationship doesn't exist in entity.
        case undefined
    }
}

// MARK: -

extension String {
    internal init(id: NSManagedObjectID) {
        self = id.uriRepresentation().absoluteString
    }
}
