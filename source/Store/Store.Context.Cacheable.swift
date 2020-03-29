import CoreData

open class CacheableContext: Context {
    public convenience init(coordinator: Coordinator, concurrency: NSManagedObjectContextConcurrencyType, cache: ModelCache? = nil) {
        self.init(coordinator: coordinator, concurrency: concurrency)
        if let cache = cache { self.cache = cache }
    }

    // MARK: -

    open var cache: ModelCache = DictionaryModelCache()
}
