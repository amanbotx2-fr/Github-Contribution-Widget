import Foundation

struct ContributionProfile {
    let username: String
    let isActive: Bool
    let totalContributions: Int
    let currentStreak: Int
    let longestStreak: Int
    let days: [ContributionDay]

    static let mock = ContributionProfile.makeMock()
}

struct ContributionDay: Identifiable {
    let date: Date
    let count: Int

    var id: Date { date }

    var level: Int {
        switch count {
        case 0:
            return 0
        case 1...2:
            return 1
        case 3...5:
            return 2
        case 6...9:
            return 3
        default:
            return 4
        }
    }
}

private extension ContributionProfile {
    static func makeMock() -> ContributionProfile {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let dayCount = 26 * 7

        let days = (0..<dayCount).compactMap { offset -> ContributionDay? in
            guard let date = calendar.date(byAdding: .day, value: offset - dayCount + 1, to: today) else {
                return nil
            }

            let wave = (offset * 7 + offset / 3) % 13
            let isWeekend = calendar.component(.weekday, from: date) == 1 || calendar.component(.weekday, from: date) == 7
            let base = isWeekend ? max(0, wave - 8) : max(0, wave - 4)
            let burst = offset % 17 == 0 ? 8 : 0
            let quiet = offset % 29 == 0 ? 0 : base + burst

            return ContributionDay(date: date, count: quiet)
        }

        return ContributionProfile(
            username: "aman kumar",
            isActive: true,
            totalContributions: 1243,
            currentStreak: 18,
            longestStreak: 128,
            days: days
        )
    }
}
