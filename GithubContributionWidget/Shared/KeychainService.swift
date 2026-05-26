import Foundation
import Security

enum KeychainService {
    private static let service = "com.amankumar.githubcontributionwidget.github"
    private static let tokenAccount = "personal-access-token"

    static func readGitHubToken() -> String {
        (try? readPassword(account: tokenAccount)) ?? ""
    }

    static func saveGitHubToken(_ token: String) {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if trimmedToken.isEmpty {
                try deletePassword(account: tokenAccount)
            } else {
                try savePassword(trimmedToken, account: tokenAccount)
            }
        } catch {
            // Keep token failures private. Callers fall back to mock data when reads fail.
        }
    }

    private static func readPassword(account: String) throws -> String {
        var query = baseQuery(account: account)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            return ""
        }

        guard status == errSecSuccess, let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unhandledStatus(status)
        }

        return value
    }

    private static func savePassword(_ password: String, account: String) throws {
        let data = Data(password.utf8)
        var query = baseQuery(account: account)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(query.merging([kSecValueData as String: data]) { _, new in new } as CFDictionary, nil)

        if status == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(baseQuery(account: account) as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledStatus(updateStatus)
            }
            return
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }
    }

    private static func deletePassword(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
    }

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

private enum KeychainError: Error {
    case unhandledStatus(OSStatus)
}
