import Foundation
public class DatabaseHelper {

    /// The application group identifier defines a group of apps or extensions that have access to a shared container.
    ///
    /// We read this value from the app's entitlements at runtime so local forks can run without hardcoding
    /// Delta Chat's App Group identifier.
    public static var applicationGroupIdentifier: String? {
        DcSharedContainer.applicationGroupIdentifier
    }

    public init() {}

    public var sharedDbFile: String {
        let storeURL = DcSharedContainer.containerURL().appendingPathComponent("messenger.db")
        return storeURL.path
    }

    var localDbFile: String {
        return localDocumentsDir.appendingPathComponent("messenger.db").path
    }

    var localDocumentsDir: URL {
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        return URL(fileURLWithPath: paths[0], isDirectory: true)
    }

    public var unmanagedDatabaseLocation: String? {
        let filemanager = FileManager.default
        if filemanager.fileExists(atPath: localDbFile) {
            return localDbFile
        } else if filemanager.fileExists(atPath: sharedDbFile) {
            return sharedDbFile
        }
        return nil
    }
}
