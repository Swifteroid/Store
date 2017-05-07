import Foundation

internal class PathUtility
{

    /*
    Requires bundle definition in injection and `Path.Root` value defined in `Info.plist`.
    */
    private static let path: [String: String] = Bundle(for: PathUtility.self).object(forInfoDictionaryKey: "Path") as! [String: String]

    private static let root: URL = URL(fileURLWithPath: PathUtility.path["Root"]!, isDirectory: true)

    // MARK: -

    internal static var testUrl: URL {
        return self.root.appendingPathComponent("test", isDirectory: true)
    }

    internal static func testUrl(directory: String? = nil, file: String? = nil) -> URL {
        var url: URL = self.testUrl
        if let component: String = directory { url.appendPathComponent(component, isDirectory: true) }
        if let component: String = file { url.appendPathComponent(component, isDirectory: false) }
        return url
    }

    // MARK: -

    /*
    Returns output directory for test products.
    */
    internal static var outputUrl: URL {
        return self.root.appendingPathComponent("product/test", isDirectory: true)
    }

    internal static func outputUrl(directory: String? = nil, file: String? = nil, cleanup: Bool = false) -> URL {
        let fileManager: FileManager = FileManager.default
        var url: URL = self.outputUrl

        if let component: String = directory { url.appendPathComponent(component, isDirectory: true) }
        if let component: String = file { url.appendPathComponent(component, isDirectory: false) }
        if cleanup && fileManager.fileExists(atPath: url.path) { try! fileManager.removeItem(at: url) }

        return url
    }

    // MARK: -

    internal static var librarySchemaUrl: URL {
        return Bundle(for: self).url(forResource: "library", withExtension: "momd")!
    }
}