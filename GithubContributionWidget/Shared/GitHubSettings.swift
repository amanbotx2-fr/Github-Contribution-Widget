import Foundation

enum GitHubSettings {
    static let appGroupIdentifier = "group.com.amankumar.githubcontributionwidget"
    static let usernameKey = "github.username"
    static let selectedYearKey = "github.selectedYear"
    private static let legacyTokenKey = "github.personalAccessToken"

    static var store: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    static var username: String {
        store.string(forKey: usernameKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static var personalAccessToken: String {
        KeychainService.readGitHubToken()
    }

    static func setPersonalAccessToken(_ token: String) {
        KeychainService.saveGitHubToken(token)
        store.removeObject(forKey: legacyTokenKey)
    }

    static func migrateLegacyTokenIfNeeded() {
        let existingToken = personalAccessToken
        let legacyToken = store.string(forKey: legacyTokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if existingToken.isEmpty, !legacyToken.isEmpty {
            KeychainService.saveGitHubToken(legacyToken)
        }

        store.removeObject(forKey: legacyTokenKey)
    }

    static var selectedYear: Int {
        let storedYear = store.integer(forKey: selectedYearKey)
        if storedYear > 0 {
            return storedYear
        }

        return Calendar.current.component(.year, from: Date())
    }
}
