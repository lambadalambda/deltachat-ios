import Foundation
import Security

/// Central place for shared container and keychain settings.
///
/// Delta Chat iOS uses an App Group to share data between the main app and its extensions.
/// For local development (or builds without App Group entitlements), this helper falls back to
/// the app's sandbox container so the app can still run.
public enum DcSharedContainer {
    // The official Delta Chat App Group id.
    // Local forks should patch `DC_APP_GROUP_ID` in their Info.plist files and update entitlements.
    private static let defaultAppGroupIdentifier = "group.chat.delta.ios"
    private static let infoPlistAppGroupKey = "DC_APP_GROUP_ID"
    private static let infoPlistKeychainAccessGroupKey = "DC_KEYCHAIN_ACCESS_GROUP"

    private static let fileManager = FileManager.default

    private static var didResolveContainer = false
    private static var cachedResolvedContainer: (id: String, url: URL)?

    /// The resolved App Group identifier if (and only if) the current process is actually entitled to it.
    public static var applicationGroupIdentifier: String? {
        resolveContainerIfNeeded()
        return cachedResolvedContainer?.id
    }

    /// Returns the shared container URL when an App Group is available.
    /// Falls back to the app's sandbox (Library directory) if no App Group is configured/available.
    public static func containerURL() -> URL {
        resolveContainerIfNeeded()

        if let url = cachedResolvedContainer?.url {
            return url
        }
        if let url = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first {
            return url
        }
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    public static var sharedUserDefaults: UserDefaults? {
        guard let id = applicationGroupIdentifier else { return nil }
        return UserDefaults(suiteName: id)
    }

    /// Returns the preferred keychain access group for sharing secrets between the app and its extensions.
    public static var sharedKeychainAccessGroup: String? {
        // Optional override from Info.plist (useful for local forks).
        if let value = infoPlistString(infoPlistKeychainAccessGroupKey), !value.contains("$(") {
            return value
        }

        guard let appGroup = applicationGroupIdentifier else { return nil }
        guard let teamId = teamIdentifierPrefix() else { return nil }
        return teamId + "." + appGroup
    }

    private static func resolveContainerIfNeeded() {
        guard !didResolveContainer else { return }
        didResolveContainer = true

        let candidateIds = uniqueNonEmptyStrings(from: [
            infoPlistString(infoPlistAppGroupKey),
            defaultAppGroupIdentifier
        ].compactMap { $0 })

        for id in candidateIds {
            if let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: id) {
                cachedResolvedContainer = (id: id, url: url)
                return
            }
        }
    }

    private static func infoPlistString(_ key: String) -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static var cachedTeamIdentifierPrefix: String?
    private static func teamIdentifierPrefix() -> String? {
        if let cachedTeamIdentifierPrefix {
            return cachedTeamIdentifierPrefix
        }

        // Read the app identifier prefix (team id) from the access group of a keychain item
        // in the default access group.
        let account = "bundleSeedID"
        let service = "deltachat.bundleSeedID"

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecValueData as String: Data(),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus != errSecSuccess && addStatus != errSecDuplicateItem {
            return nil
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let dict = item as? [String: Any],
              let accessGroup = dict[kSecAttrAccessGroup as String] as? String,
              let prefix = accessGroup.split(separator: ".").first.map(String.init),
              !prefix.isEmpty
        else {
            return nil
        }

        cachedTeamIdentifierPrefix = prefix
        return prefix
    }

    private static func uniqueNonEmptyStrings(from values: [String]) -> [String] {
        var unique: [String] = []
        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if !unique.contains(trimmed) {
                unique.append(trimmed)
            }
        }
        return unique
    }
}
