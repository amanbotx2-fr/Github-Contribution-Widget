import SwiftUI

@main
struct GithubContributionWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 460, height: 420)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }
}
