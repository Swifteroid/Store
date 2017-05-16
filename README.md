# Store

Store is a Core Data framework that provides convenient interface for data management and migration. It's largely inspired by a more classical object-relational mapping approach and attempts to eliminate direct use of `NSManagedObject` while retaining cool parts of Core Data.

- [x] Configurable load, save and delete operations
- [x] Automatic and configurable migrations
- [x] No `NSManagedObject` inheritance
- [x] Awesome relationship management
- [x] Customisable model change observerations

## Concept 🔬

Store framework is all about balanced separation of concern. While working with data models you often want to treat them no different to any other of your code and Core Data quickly becomes a real pain when dealing with non-primitive attribute types, beyond basic relationship handling, object context management, etc. A small abstraction layer to extract data from managed objects and populate it back in is a decent way forward and this is exactly what Store is all about.

## Use 👷

Model and batch are two primary building blocks – models represent data, batches do the heavy lifting, including loading, saving and deleting. Here's a book model example from testing [sources](source/Testing/Model/Model.Book.swift):

```swift
import Store

class BookModel: InitialisableModel<NoConfiguration>, BatchableProtocol
{
    typealias Batch = BookBatch

    var title: String!
    var author: String!
    var publisher: String!
}

class BookBatch: Batch<BookModel>
{
    override func update(model: Model, with object: Object, configuration: Configuration? = nil) -> Model {
        model.title = object.value(for: Key.title)!
        model.author = object.value(for: Key.author)!
        model.publisher = object.value(for: Key.publisher)!
        return model
    }

    override func update(object: Object, with model: Model, configuration: Configuration? = nil) -> Object {
        object.value(set: model.title, for: Key.title)
        object.value(set: model.author, for: Key.author)
        object.value(set: model.publisher, for: Key.publisher)
        return object
    }
}

extension BookBatch
{
    struct Key
    {
        static let title: String = "title"
        static let author: String = "author"
        static let publisher: String = "publisher"
    }
}
```

Store relies on persistent store coordinator just like Core Data does and needs it to be set up before using. The easiest way is to set up the default coordinator, alternatively coordinators can be specified on per batch basis. The code below sets up the default coordinator and automatically [migrates](source/Store/Store.Coordinator.swift) store to latest schema version found at the given url. Versions should match their alphabetic order, thus, [semver](http://semver.org) versioning format is recommended.

```swift
let storeUrl: URL = Coordinator.url(for: "Foo")
let schemaUrl: URL = Bundle(for: self).url(forResource: "Bar", withExtension: "momd")!
Coordinator.default = Coordinator(store: storeUrl, schema: schemaUrl, handler: { true })!
```

☝️ Above you may have noticed `Coordinator.url(for: "Foo")` invocation, which [creates](source/Store/Store.Coordinator.swift) an sqlite storage file in default application support directory, e.g., `~/Library/Application Support/Foo/Store/Store.sqlite`. It has a variation that takes bundle as a parameter and automatically extracts application name or identifier.

☝️ Also worth to mention `handler: { true }`, which gets invoked if migration cannot be completed and indicates if the store file should be deleted and created anew. This is where you can notify user of a problem with alert and ask if he wants to proceed with – something that should never happen, but safe is better than sorry.

☝️ Entities should use `NSManagedObject` as their class, if class value is left empty make sure `representedClassName` attribute is removed and not set to a blank value in your `*.xdatamodeld/*.cdatamodel/contents` file to avoid compile errors.

## Motivation 🤔

Apple stack developer life is made of two parts – before working with Core Data and after. Every experience is unique, frustrating and painful. With time and luck it all comes the understanding of what's going on and rationale of why it was made that way. This obviously helps with finding piece, but not with making using Core Data simpler or prettier. Store attempts to solve these two exact points.