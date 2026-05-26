import Foundation
import Darwin

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
        let dayCount = 30 * 7

        let days = (0..<dayCount).compactMap { offset -> ContributionDay? in
            guard let date = calendar.date(byAdding: .day, value: offset - dayCount + 1, to: today) else {
                return nil
            }

            let weekday = calendar.component(.weekday, from: date)
            let isWeekend = weekday == 1 || weekday == 7
            let seasonal = Int((sin(Double(offset) * 0.21) + 1) * 3.2)
            let cadence = (offset * 5 + offset / 4) % 9
            let sprint = (offset / 21) % 3 == 1 ? 3 : 0
            let burst = [11, 37, 74, 119, 156].contains(offset) ? 8 : 0
            let restDay = offset % 19 == 0 || offset % 43 == 0
            let weekendPenalty = isWeekend ? 4 : 0
            let quiet = restDay ? 0 : max(0, seasonal + cadence + sprint + burst - weekendPenalty)

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
