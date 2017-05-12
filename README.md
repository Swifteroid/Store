# Store

Store is a Core Data framework that provides convenient interface for data management and migration. It's largely inspired by a more classical object-relational mapping approach and attempts to eliminate direct use of `NSManagedObject` while retaining cool parts of Core Data.

- [x] Configurable load, save and delete operations
- [x] Automatic and configurable migrations
- [x] No `NSManagedObject` inheritance
- [x] Awesome relationship management

## Use 🏗

Model and batch are two primary building blocks – models represent data, batches do all the heavy lifting, including loading, saving and deleting. Here's a book model example from testing [sources](source/Testing/Model/Model.Book.swift):

```swift
import Store

internal class BookModel: InitialisableModel<NoConfiguration>, BatchableProtocol
{
    internal typealias Batch = BookBatch

    internal var title: String!
    internal var author: String!
    internal var publisher: String!
}

internal class BookBatch: Batch<BookModel>
{
    override internal func update(model: Model, with object: Object, configuration: Model.Configuration? = nil) -> Model {
        model.title = object.value(for: Key.title)!
        model.author = object.value(for: Key.author)!
        model.publisher = object.value(for: Key.publisher)!
        return model
    }

    override internal func update(object: Object, with model: Model, configuration: Model.Configuration? = nil) -> Object {
        object.value(set: model.title, for: Key.title)
        object.value(set: model.author, for: Key.author)
        object.value(set: model.publisher, for: Key.publisher)
        return object
    }
}

extension BookBatch
{
    fileprivate struct Key
    {
        fileprivate static let title: String = "title"
        fileprivate static let author: String = "author"
        fileprivate static let publisher: String = "publisher"
    }
}
```

☝️ Entities should use `NSManagedObject` as their class, if class value is left empty make sure `representedClassName` attribute is removed and not set to a blank value in your `*.xdatamodeld/*.cdatamodel/contents` file to avoid compile errors.

## Motivation 🤔

Apple stack developer life is made of two parts – before working with Core Data and after. Every experience is unique, frustrating and painful. With time and luck it all comes the understanding of what's going on and rationale of why it was made that way. This obviously helps with finding piece, but not with making using Core Data simpler or prettier. Store attempts to solve these two exact points.