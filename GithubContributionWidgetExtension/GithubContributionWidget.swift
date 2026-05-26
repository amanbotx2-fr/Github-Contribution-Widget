import SwiftUI
import WidgetKit

struct GithubContributionProvider: TimelineProvider {
    func placeholder(in context: Context) -> GithubContributionEntry {
        GithubContributionEntry(date: Date(), profile: .mock)
    }

    func getSnapshot(in context: Context, completion: @escaping (GithubContributionEntry) -> Void) {
        completion(GithubContributionEntry(date: Date(), profile: .mock))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GithubContributionEntry>) -> Void) {
        let entry = GithubContributionEntry(date: Date(), profile: .mock)
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: entry.date) ?? entry.date
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct GithubContributionEntry: TimelineEntry {
    let date: Date
    let profile: ContributionProfile
}

struct GithubContributionWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: GithubContributionEntry

    var body: some View {
        ContributionWidgetCard(profile: entry.profile, size: widgetSize)
            .containerBackground(for: .widget) {
                GlassWidgetBackground()
            }
    }

    private var widgetSize: ContributionWidgetSize {
        family == .systemLarge ? .large : .medium
    }
}

struct GithubContributionWidget: Widget {
    private let kind = "GithubContributionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GithubContributionProvider()) { entry in
            GithubContributionWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GitHub Contributions")
        .description("Minimal GitHub contribution activity with mock data.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
