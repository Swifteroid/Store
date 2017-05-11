# Store

Store is a Core Data framework that provides convenient interface for data management and migration. It's largely inspired by a more classical object-relational mapping approach and attempts to eliminate direct use of `NSManagedObject` while retaining cool parts of Core Data. Check out [testing](source/Testing) sources for code samples.

☝️ Entities should use `NSManagedObject` as their class, if class value is left empty make sure `representedClassName` attribute is removed and not set to a blank value in your `*.xdatamodeld/*.cdatamodel/contents` file to avoid compile errors.

- [x] Configurable load, save and delete operations
- [x] Automatic and configurable migrations
- [x] No `NSManagedObject` inheritance
- [x] Easy relationship management