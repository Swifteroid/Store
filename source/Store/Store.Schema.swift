import CoreData
import Foundation

/// Schema is an attempt to avoid confusion between core data object models and actual store models.

public typealias Schema = NSManagedObjectModel

private let entityNameExpression = try! NSRegularExpression(pattern: "(\\w+)(?:Model|Batch)")
private var entityNameCache: [String: String] = [:]

extension Schema
{
    open func entity(for name: String) -> Entity? {
        return self.entitiesByName[name]
    }

    open func entity<Model:ModelProtocol>(for model: Model) -> Entity? {
        return entity(for: type(of: model))
    }

    open func entity<Model:ModelProtocol>(for model: Model.Type) -> Entity? {
        return entity(for: model)
    }

    open func entity<Batch:BatchProtocol>(for batch: Batch) -> Entity? {
        return entity(for: type(of: batch))
    }

    open func entity<Batch:BatchProtocol>(for batch: Batch.Type) -> Entity? {
        return entity(for: batch)
    }

    private func entity(for type: Any.Type) -> Entity? {
        let string: String = String(describing: type)
        let name: String

        if let string: String = entityNameCache[string] {
            name = string
        } else if let match: NSTextCheckingResult = entityNameExpression.firstMatch(in: string, range: NSRange(0 ..< string.count)) {
            name = (string as NSString).substring(with: match.range(at: 1))
            entityNameCache[string] = name
        } else {
            name = string
        }

        return self.entitiesByName[name]
    }

    // MARK: -

    open func compatible(with metadata: [String: Any]) -> Bool {
        return self.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }

    // MARK: -

    /// Returns all schemas at the specified url, which is typically a compiled `momd` type file. Schemas will be sorted by name
    /// in ascending order, which should go in line if semver is used for versioning.

    open class func schemas(at url: URL) -> [(Schema, URL)] {
        var schemas: [(Schema, URL)] = []

        for case let file as URL in FileManager.default.enumerator(at: url, includingPropertiesForKeys: [])! {
            if file.pathExtension == "mom", let schema: Schema = Schema(contentsOf: file) {
                schemas.append((schema, file))
            }
        }

        return schemas.sorted(by: { $0.1.absoluteString < $1.1.absoluteString })
    }
}