import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage(GitHubSettings.usernameKey, store: GitHubSettings.store) private var username = ""
    @AppStorage(GitHubSettings.selectedYearKey, store: GitHubSettings.store) private var selectedYear = Calendar.current.component(.year, from: Date())

    @State private var token = ""
    @State private var status = SettingsStatus.fallback("Mock fallback is active until username and token are saved.")

    private var yearRange: ClosedRange<Int> {
        2008...Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        Form {
            Section {
                TextField("GitHub username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveAndReloadWidget)

                SecureField("Personal access token", text: $token)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveAndReloadWidget)

                Stepper(value: $selectedYear, in: yearRange) {
                    Text("Year: \(selectedYear)")
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
                .disabled(status == .checking)

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
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            status = .fallback("Mock fallback is active because no username is saved.")
        } else if token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty, !trimmedToken.isEmpty else {
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
            status = .success("Fetched \(profile.totalContributions.formatted()) contributions for \(selectedYear). Widget refreshed.")
            saveAndReloadWidget()
        } catch {
            status = .error("GitHub fetch failed. Widget will continue using mock fallback.")
            saveAndReloadWidget()
        }
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
