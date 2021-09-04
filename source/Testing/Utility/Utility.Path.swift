import Foundation

internal class PathUtility {

    /// Requires bundle definition in injection and `Path.Root` value defined in `Info.plist`.
    private static let path: [String: String] = Bundle(for: PathUtility.self).object(forInfoDictionaryKey: "Path") as! [String: String]
    private static let rootURL: URL = URL(fileURLWithPath: PathUtility.path["Root"]!, isDirectory: true)

    // MARK: -

    internal static var testURL: URL {
        self.rootURL.appendingPathComponent("test", isDirectory: true)
    }

    internal static func testURL(directory: String? = nil, file: String? = nil) -> URL {
        var url: URL = self.testURL
        if let component: String = directory { url.appendPathComponent(component, isDirectory: true) }
        if let component: String = file { url.appendPathComponent(component, isDirectory: false) }
        return url
    }

    // MARK: -

    /// Returns output directory for test products.
    internal static var outputURL: URL {
        self.rootURL.appendingPathComponent("product/test", isDirectory: true)
    }

    internal static func outputURL(directory: String? = nil, file: String? = nil, cleanup: Bool = false) -> URL {
        let fileManager: FileManager = FileManager.default
        var url: URL = self.outputURL
        if let component: String = directory { url.appendPathComponent(component, isDirectory: true) }
        if let component: String = file { url.appendPathComponent(component, isDirectory: false) }
        if cleanup && fileManager.fileExists(atPath: url.path) { try! fileManager.removeItem(at: url) }
        return url
    }

    // MARK: -

    internal static var librarySchemaURL: URL {
        Bundle(for: self).url(forResource: "library", withExtension: "momd")!
    }

    internal static var genericSchemaURL: URL {
        Bundle(for: self).url(forResource: "generic", withExtension: "momd")!
    }
}
