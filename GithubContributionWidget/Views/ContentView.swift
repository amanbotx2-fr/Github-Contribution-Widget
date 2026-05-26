import SwiftUI

struct ContentView: View {
    private let profile = ContributionProfile.mock

    var body: some View {
        ZStack {
            AppBackdrop()

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Github Contribution Widget")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Mock data preview for macOS WidgetKit medium and large families.")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.62))
                }

                HStack(alignment: .top, spacing: 18) {
                    WidgetPreviewShell(label: "Medium") {
                        ContributionWidgetCard(profile: profile, size: .medium)
                            .frame(width: 360, height: 170)
                    }

                    WidgetPreviewShell(label: "Large") {
                        ContributionWidgetCard(profile: profile, size: .large)
                            .frame(width: 360, height: 360)
                    }
                }
            }
            .padding(28)
        }
    }
}

private struct WidgetPreviewShell<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.58))

            content
        }
    }
}

private struct AppBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.09),
                    Color(red: 0.04, green: 0.04, blue: 0.16),
                    Color(red: 0.01, green: 0.02, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.26, green: 0.15, blue: 0.52).opacity(0.42))
                .blur(radius: 56)
                .frame(width: 340, height: 340)
                .offset(x: -260, y: -140)

            Circle()
                .fill(Color(red: 0.10, green: 0.35, blue: 0.38).opacity(0.22))
                .blur(radius: 70)
                .frame(width: 300, height: 300)
                .offset(x: 280, y: 160)
        }
        .ignoresSafeArea()
    }
}
