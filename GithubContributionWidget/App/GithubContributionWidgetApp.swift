import SwiftUI

@main
struct GithubContributionWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 720, height: 460)

        Settings {
            SettingsView()
        }
    }
}
