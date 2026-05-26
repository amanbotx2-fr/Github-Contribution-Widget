import Foundation

enum GitHubSettings {
    static let appGroupIdentifier = "group.com.amankumar.githubcontributionwidget"
    static let usernameKey = "github.username"
    static let tokenKey = "github.personalAccessToken"
    static let selectedYearKey = "github.selectedYear"

    static var store: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    static var username: String {
        store.string(forKey: usernameKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static var personalAccessToken: String {
        store.string(forKey: tokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static var selectedYear: Int {
        let storedYear = store.integer(forKey: selectedYearKey)
        if storedYear > 0 {
            return storedYear
        }

        return Calendar.current.component(.year, from: Date())
    }
}
