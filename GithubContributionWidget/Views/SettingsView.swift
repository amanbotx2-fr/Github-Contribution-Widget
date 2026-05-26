import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage(GitHubSettings.usernameKey, store: GitHubSettings.store) private var username = ""
    @AppStorage(GitHubSettings.tokenKey, store: GitHubSettings.store) private var token = ""
    @AppStorage(GitHubSettings.selectedYearKey, store: GitHubSettings.store) private var selectedYear = Calendar.current.component(.year, from: Date())

    private var yearRange: ClosedRange<Int> {
        2008...Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        Form {
            Section {
                TextField("GitHub username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(reloadWidget)

                SecureField("Personal access token", text: $token)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(reloadWidget)

                Stepper(value: $selectedYear, in: yearRange) {
                    Text("Year: \(selectedYear)")
                }
            } footer: {
                Text("The widget uses mock data when either field is empty or GitHub cannot be reached.")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()

                Button("Refresh Widget") {
                    reloadWidget()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 420)
        .onChange(of: username) { _, _ in reloadWidget() }
        .onChange(of: token) { _, _ in reloadWidget() }
        .onChange(of: selectedYear) { _, _ in reloadWidget() }
    }

    private func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
