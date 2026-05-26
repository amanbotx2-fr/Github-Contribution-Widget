import SwiftUI

enum ContributionWidgetSize {
    case medium
    case large

    var cornerRadius: CGFloat {
        switch self {
        case .medium:
            return 18
        case .large:
            return 22
        }
    }

    var contentPadding: CGFloat {
        switch self {
        case .medium:
            return 12
        case .large:
            return 16
        }
    }

    var heatmapColumns: Int {
        switch self {
        case .medium:
            return 13
        case .large:
            return 23
        }
    }

    var heatmapCell: CGFloat {
        switch self {
        case .medium:
            return 6.5
        case .large:
            return 8.5
        }
    }

    var heatmapGap: CGFloat {
        switch self {
        case .medium:
            return 2.5
        case .large:
            return 3.5
        }
    }

    var heatmapWidth: CGFloat {
        CGFloat(heatmapColumns) * heatmapCell + CGFloat(heatmapColumns - 1) * heatmapGap
    }

    var heatmapHeight: CGFloat {
        7 * heatmapCell + 6 * heatmapGap
    }

    var legendCell: CGFloat {
        switch self {
        case .medium:
            return 7
        case .large:
            return 9
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
        .padding(size.contentPadding)
        .background(GlassWidgetBackground())
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), Color.white.opacity(0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(size == .medium ? 0.20 : 0.26), radius: size == .medium ? 10 : 16, y: 8)
        .environment(\.colorScheme, .dark)
    }

    private var mediumLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 9) {
                HeaderView(profile: profile, compact: true)

                VStack(alignment: .leading, spacing: 6) {
                    MetricView(value: profile.totalContributions.formatted(), label: "Contributions", highlighted: true, compact: true)

                    HStack(spacing: 10) {
                        MetricView(value: "\(profile.currentStreak)", label: "Current", highlighted: false, compact: true)
                        MetricView(value: "\(profile.longestStreak)", label: "Longest", highlighted: false, compact: true)
                    }
                }
            }
            .frame(width: 124, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                ContributionHeatmapView(profile: profile, size: size)
                ContributionLegendView(size: size)
            }
            .frame(width: size.heatmapWidth, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(profile: profile, compact: false)

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                MetricView(value: profile.totalContributions.formatted(), label: "Contributions", highlighted: true, compact: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
                MetricView(value: "\(profile.currentStreak)", label: "Current streak", highlighted: false, compact: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
                MetricView(value: "\(profile.longestStreak)", label: "Longest streak", highlighted: false, compact: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 12) {
                ContributionHeatmapView(profile: profile, size: size)
                ContributionLegendView(size: size)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct HeaderView: View {
    let profile: ContributionProfile
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 8 : 10) {
            GithubAvatarView(size: compact ? 30 : 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.username)
                    .font((compact ? Font.subheadline : Font.callout).weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.white)

                HStack(spacing: 5) {
                    Circle()
                        .fill(profile.isActive ? Color.githubBrightGreen : Color.secondary)
                        .frame(width: compact ? 6 : 7, height: compact ? 6 : 7)

                    Text(profile.isActive ? "Active now" : "Offline")
                        .font(compact ? .caption2 : .caption)
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
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(metricFont)
                .minimumScaleFactor(0.76)
                .lineLimit(1)
                .foregroundStyle(highlighted ? Color.githubBrightGreen : Color.white)

            Text(label)
                .font(compact ? .caption2 : .caption)
                .lineLimit(1)
                .foregroundStyle(.white.opacity(0.58))
        }
    }

    private var metricFont: Font {
        if highlighted {
            return .system(size: compact ? 24 : 30, weight: .bold, design: .rounded)
        }

        return compact ? .caption.weight(.semibold) : .headline.weight(.semibold)
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
        .frame(width: size.heatmapWidth, height: size.heatmapHeight, alignment: .topLeading)
        .clipped()
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
    let size: ContributionWidgetSize

    var body: some View {
        HStack(spacing: size == .medium ? 5 : 6) {
            Text("Less")
                .foregroundStyle(.white.opacity(0.62))

            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: size.legendCell * 0.28, style: .continuous)
                    .fill(Color.contributionLevel(level))
                    .frame(width: size.legendCell, height: size.legendCell)
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
                    Color(red: 0.12, green: 0.13, blue: 0.23).opacity(0.82),
                    Color(red: 0.03, green: 0.05, blue: 0.10).opacity(0.94),
                    Color(red: 0.02, green: 0.03, blue: 0.07).opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.white.opacity(0.12), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 190
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.16),
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
