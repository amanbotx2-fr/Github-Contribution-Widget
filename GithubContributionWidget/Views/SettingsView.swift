import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage(GitHubSettings.usernameKey, store: GitHubSettings.store) private var username = ""
    @AppStorage(GitHubSettings.selectedYearKey, store: GitHubSettings.store) private var selectedYear = Calendar.current.component(.year, from: Date())

    @State private var token = ""
    @State private var status = SettingsStatus.fallback("Mock fallback is active until username and token are saved.")

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var recentYears: [Int] {
        Array(stride(from: currentYear, through: 2018, by: -1))
    }

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedToken: String {
        token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var validationMessage: String? {
        if trimmedUsername.isEmpty {
            return "Enter a GitHub username."
        }

        if trimmedToken.isEmpty {
            return "Paste a GitHub Personal Access Token."
        }

        if !recentYears.contains(selectedYear) {
            return "Choose a year between 2018 and \(currentYear)."
        }

        return nil
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Connect GitHub")
                        .font(.headline)

                    Text("Create a GitHub Personal Access Token, copy it once, and paste it below. Public contribution data does not need repository write access.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Link("Open GitHub token settings", destination: URL(string: "https://github.com/settings/tokens")!)
                        .font(.callout)
                }
                .padding(.vertical, 2)
            }

            Section {
                TextField("GitHub username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveAndReloadWidget)

                SecureField("Personal access token", text: $token)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveAndReloadWidget)

                Picker("Year", selection: $selectedYear) {
                    ForEach(recentYears, id: \.self) { year in
                        Text(String(year))
                            .tag(year)
                    }
                }
                .pickerStyle(.menu)

                if let validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The widget uses mock data when either field is empty or GitHub cannot be reached.")
                        .foregroundStyle(.secondary)

                    Label(status.message, systemImage: status.systemImage)
                        .foregroundStyle(status.foregroundStyle)
                }
            }

            HStack {
                Button("Test Fetch") {
                    Task {
                        await testFetch()
                    }
                }
                .disabled(status == .checking || validationMessage != nil)

                Spacer()

                Button("Refresh Widget") {
                    saveAndReloadWidget()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 420)
        .onAppear {
            GitHubSettings.migrateLegacyTokenIfNeeded()
            token = GitHubSettings.personalAccessToken
            if !recentYears.contains(selectedYear) {
                selectedYear = currentYear
            }
            updateStatusForStoredValues()
        }
        .onChange(of: username) { _, _ in
            updateStatusForStoredValues()
            saveAndReloadWidget()
        }
        .onChange(of: token) { _, _ in
            updateStatusForStoredValues()
            saveAndReloadWidget()
        }
        .onChange(of: selectedYear) { _, _ in
            updateStatusForStoredValues()
            saveAndReloadWidget()
        }
    }

    private func updateStatusForStoredValues() {
        if let validationMessage {
            status = .fallback(validationMessage)
        } else if trimmedUsername.isEmpty {
            status = .fallback("Mock fallback is active because no username is saved.")
        } else if trimmedToken.isEmpty {
            status = .fallback("Mock fallback is active because no token is saved.")
        } else {
            status = .ready("Settings saved for \(selectedYear). The widget will fetch GitHub data on refresh.")
        }
    }

    private func saveAndReloadWidget() {
        GitHubSettings.setPersonalAccessToken(token)
        GitHubSettings.store.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
        if case .ready = status {
            status = .ready("Settings saved for \(selectedYear). Widget refresh requested.")
        }
    }

    @MainActor
    private func testFetch() async {
        guard validationMessage == nil else {
            updateStatusForStoredValues()
            saveAndReloadWidget()
            return
        }

        status = .checking

        do {
            let profile = try await GitHubService().contributionProfile(
                username: trimmedUsername,
                token: trimmedToken,
                year: selectedYear
            )
            status = .success(successMessage(for: profile))
            saveAndReloadWidget()
        } catch {
            status = .error("\(error.localizedDescription) Widget will continue using mock fallback.")
            saveAndReloadWidget()
        }
    }

    private func successMessage(for profile: ContributionProfile) -> String {
        guard let debug = profile.fetchDebug else {
            return "GitHub API total: \(profile.totalContributions.formatted()) contributions for \(selectedYear). Widget refreshed."
        }

        let debugText = "username: \(debug.username), year: \(debug.year), from: \(debug.from), to: \(debug.to), API total: \(debug.apiTotal), service: \(debug.serviceVersion)"

        if debug.restrictedContributionsCount > 0 {
            return "\(debug.apiTotal) public contributions fetched. GitHub profile may include private contributions. \(debugText), restricted/private count: \(debug.restrictedContributionsCount)."
        }

        return "GitHub API total: \(debug.apiTotal) contributions. \(debugText). Widget refreshed."
    }
}

private enum SettingsStatus: Equatable {
    case fallback(String)
    case ready(String)
    case checking
    case success(String)
    case error(String)

    var message: String {
        switch self {
        case .fallback(let message), .ready(let message), .success(let message), .error(let message):
            return message
        case .checking:
            return "Checking GitHub contribution data..."
        }
    }

    var systemImage: String {
        switch self {
        case .fallback:
            return "exclamationmark.triangle"
        case .ready:
            return "checkmark.circle"
        case .checking:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.octagon"
        }
    }

    var foregroundStyle: Color {
        switch self {
        case .fallback:
            return .orange
        case .ready:
            return .secondary
        case .checking:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}
