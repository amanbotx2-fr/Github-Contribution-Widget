import SwiftUI

enum ContributionWidgetSize {
    case medium
    case large

    var heatmapColumns: Int {
        switch self {
        case .medium:
            return 14
        case .large:
            return 24
        }
    }

    var heatmapCell: CGFloat {
        switch self {
        case .medium:
            return 6
        case .large:
            return 9
        }
    }

    var heatmapGap: CGFloat {
        switch self {
        case .medium:
            return 3
        case .large:
            return 4
        }
    }
}

struct ContributionWidgetCard: View {
    let profile: ContributionProfile
    let size: ContributionWidgetSize

    var body: some View {
        Group {
            switch size {
            case .medium:
                mediumLayout
            case .large:
                largeLayout
            }
        }
        .padding(size == .medium ? 14 : 18)
        .background(GlassWidgetBackground())
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        }
        .environment(\.colorScheme, .dark)
    }

    private var mediumLayout: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HeaderView(profile: profile, compact: true)

                VStack(alignment: .leading, spacing: 8) {
                    MetricView(value: profile.totalContributions.formatted(), label: "Contributions", highlighted: true)
                    HStack(spacing: 14) {
                        MetricView(value: "\(profile.currentStreak)", label: "Current", highlighted: false)
                        MetricView(value: "\(profile.longestStreak)", label: "Longest", highlighted: false)
                    }
                }
            }
            .frame(width: 132, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                ContributionHeatmapView(profile: profile, size: size)
                ContributionLegendView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderView(profile: profile, compact: false)

            HStack(spacing: 18) {
                MetricView(value: profile.totalContributions.formatted(), label: "Contributions", highlighted: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                MetricView(value: "\(profile.currentStreak)", label: "Current streak", highlighted: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
                MetricView(value: "\(profile.longestStreak)", label: "Longest streak", highlighted: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 12) {
                ContributionHeatmapView(profile: profile, size: size)
                ContributionLegendView()
            }
        }
    }
}

private struct HeaderView: View {
    let profile: ContributionProfile
    let compact: Bool

    var body: some View {
        HStack(spacing: 10) {
            GithubAvatarView(size: compact ? 34 : 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.username)
                    .font((compact ? Font.callout : Font.title3).weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.white)

                HStack(spacing: 5) {
                    Circle()
                        .fill(profile.isActive ? Color.githubBrightGreen : Color.secondary)
                        .frame(width: 7, height: 7)

                    Text(profile.isActive ? "Active now" : "Offline")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
        }
    }
}

private struct GithubAvatarView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.96))

            Text("GH")
                .font(.system(size: size * 0.34, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.05, green: 0.06, blue: 0.10))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        .accessibilityLabel("GitHub avatar")
    }
}

private struct MetricView: View {
    let value: String
    let label: String
    let highlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(highlighted ? .system(size: 28, weight: .bold, design: .rounded) : .headline.weight(.semibold))
                .minimumScaleFactor(0.76)
                .lineLimit(1)
                .foregroundStyle(highlighted ? Color.githubBrightGreen : Color.white)

            Text(label)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.white.opacity(0.62))
        }
    }
}

private struct ContributionHeatmapView: View {
    let profile: ContributionProfile
    let size: ContributionWidgetSize

    private var visibleDays: [ContributionDay] {
        Array(profile.days.suffix(size.heatmapColumns * 7))
    }

    var body: some View {
        HStack(alignment: .top, spacing: size.heatmapGap) {
            ForEach(0..<size.heatmapColumns, id: \.self) { column in
                VStack(spacing: size.heatmapGap) {
                    ForEach(0..<7, id: \.self) { row in
                        let index = column * 7 + row
                        HeatmapCell(level: index < visibleDays.count ? visibleDays[index].level : 0, side: size.heatmapCell)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Contribution heatmap")
    }
}

private struct HeatmapCell: View {
    let level: Int
    let side: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: max(2, side * 0.28), style: .continuous)
            .fill(Color.contributionLevel(level))
            .frame(width: side, height: side)
    }
}

private struct ContributionLegendView: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("Less")
                .foregroundStyle(.white.opacity(0.62))

            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.contributionLevel(level))
                    .frame(width: 10, height: 10)
            }

            Text("More")
                .foregroundStyle(.white.opacity(0.62))
        }
        .font(.caption2)
        .accessibilityLabel("Less to more contribution legend")
    }
}

struct GlassWidgetBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.20).opacity(0.92),
                    Color(red: 0.02, green: 0.04, blue: 0.09).opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.02),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private extension Color {
    static let githubBrightGreen = Color(red: 0.26, green: 0.82, blue: 0.34)

    static func contributionLevel(_ level: Int) -> Color {
        switch level {
        case 1:
            return Color(red: 0.06, green: 0.28, blue: 0.15)
        case 2:
            return Color(red: 0.10, green: 0.48, blue: 0.22)
        case 3:
            return Color(red: 0.18, green: 0.66, blue: 0.29)
        case 4:
            return Color(red: 0.47, green: 0.93, blue: 0.36)
        default:
            return Color.white.opacity(0.08)
        }
    }
}
