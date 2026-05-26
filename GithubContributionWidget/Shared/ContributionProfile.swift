import Foundation
import Darwin

struct ContributionProfile {
    let username: String
    let isActive: Bool
    let totalContributions: Int
    let currentStreak: Int
    let longestStreak: Int
    let days: [ContributionDay]
    let fetchDebug: ContributionFetchDebug?

    static let mock = ContributionProfile.makeMock()

    init(username: String, isActive: Bool, totalContributions: Int, currentStreak: Int, longestStreak: Int, days: [ContributionDay], fetchDebug: ContributionFetchDebug? = nil) {
        self.username = username
        self.isActive = isActive
        self.totalContributions = totalContributions
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.days = days
        self.fetchDebug = fetchDebug
    }

    init(username: String, isActive: Bool, totalContributions: Int, days: [ContributionDay], fetchDebug: ContributionFetchDebug? = nil) {
        let sortedDays = days.sorted { $0.date < $1.date }
        let streaks = Self.streaks(from: sortedDays)

        self.init(
            username: username,
            isActive: isActive,
            totalContributions: totalContributions,
            currentStreak: streaks.current,
            longestStreak: streaks.longest,
            days: sortedDays,
            fetchDebug: fetchDebug
        )
    }
}

struct ContributionFetchDebug {
    let serviceVersion: String
    let username: String
    let year: Int
    let from: String
    let to: String
    let apiTotal: Int
    let restrictedContributionsCount: Int

    var consoleDescription: String {
        "version=\(serviceVersion) username=\(username) year=\(year) from=\(from) to=\(to) apiTotal=\(apiTotal) restrictedContributionsCount=\(restrictedContributionsCount)"
    }
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
    static func streaks(from days: [ContributionDay]) -> (current: Int, longest: Int) {
        var longest = 0
        var running = 0

        for day in days {
            if day.count > 0 {
                running += 1
                longest = max(longest, running)
            } else {
                running = 0
            }
        }

        var current = 0
        for day in days.reversed() {
            if day.count > 0 {
                current += 1
            } else if current > 0 {
                break
            }
        }

        return (current, longest)
    }

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
            totalContributions: days.reduce(0) { $0 + $1.count },
            days: days
        )
    }
}
