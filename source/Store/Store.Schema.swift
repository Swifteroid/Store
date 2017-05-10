import CoreData
import Foundation

/*
Schema is an attempt to avoid confusion between core data object models and actual store models.
*/
public typealias Schema = NSManagedObjectModel

extension Schema
{
    open func entity<Model:ModelProtocol>(for model: Model) -> NSEntityDescription? {
        return entity(for: type(of: model))
    }

    open func entity<Batch:BatchProtocol>(for set: Batch) -> NSEntityDescription? {
        return entity(for: type(of: set))
    }

    private func entity(for type: Any.Type) -> NSEntityDescription? {
        let string: String = String(describing: type)
        let expression: NSRegularExpression = try! NSRegularExpression(pattern: "(\\w+)(?:Model|Batch)")

        if let match: NSTextCheckingResult = expression.firstMatch(in: string, range: NSRange(0 ..< string.characters.count)) {
            return self.entitiesByName[(string as NSString).substring(with: match.rangeAt(1))]
        }

        return nil
    }

    // MARK: -

    /*
    Returns all schemas at the specified url, which is typically a compiled `momd` type file. Schemas will be sorted by name
    in ascending order, which should go in line if semver is used for versioning.
    */
    open class func schemas(at url: URL) -> [(Schema, URL)] {
        var schemas: [(Schema, URL)] = []

        for case let file as URL in FileManager.default.enumerator(at: url, includingPropertiesForKeys: [])! {
            if file.pathExtension == "mom", let schema: Schema = Schema(contentsOf: file) {
                schemas.append(schema, file)
            }
        }

        return schemas.sorted(by: { $0.1.absoluteString < $1.1.absoluteString })
    }
}