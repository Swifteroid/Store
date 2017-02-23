import Foundation

extension FileManager
{
    internal func directoryExists(atUrl url: URL, create: Bool) -> Bool {
        var directory: ObjCBool = ObjCBool(false)
        let exists: Bool = self.fileExists(atPath: url.path, isDirectory: &directory)

        if exists && directory.boolValue {
            return true
        } else if exists {
            return false
        }

        do {
            try self.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return false
        }

        return true
    }
}