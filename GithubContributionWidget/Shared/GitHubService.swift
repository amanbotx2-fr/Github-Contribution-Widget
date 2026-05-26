import Foundation

enum GitHubServiceError: Error {
    case missingCredentials
    case invalidResponse
}

struct GitHubService {
    private let endpoint = URL(string: "https://api.github.com/graphql")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func contributionProfile(username: String, token: String, year: Int = Calendar.current.component(.year, from: Date())) async throws -> ContributionProfile {
        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = token.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !username.isEmpty, !token.isEmpty else {
            throw GitHubServiceError.missingCredentials
        }

        let calendar = Calendar(identifier: .gregorian)
        var startComponents = DateComponents()
        startComponents.calendar = calendar
        startComponents.year = year
        startComponents.month = 1
        startComponents.day = 1
        startComponents.timeZone = TimeZone(secondsFromGMT: 0)

        var endComponents = startComponents
        endComponents.year = year + 1

        guard let from = startComponents.date, let to = endComponents.date else {
            throw GitHubServiceError.invalidResponse
        }

        let requestBody = GraphQLRequest(
            query: Self.contributionCalendarQuery,
            variables: GraphQLVariables(username: username, from: from.iso8601String, to: to.iso8601String)
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw GitHubServiceError.invalidResponse
        }

        let graphQLResponse = try JSONDecoder.github.decode(GraphQLResponse.self, from: data)
        if graphQLResponse.errors?.isEmpty == false {
            throw GitHubServiceError.invalidResponse
        }

        guard let user = graphQLResponse.data?.user else {
            throw GitHubServiceError.invalidResponse
        }

        return ContributionProfile(
            username: user.login,
            isActive: true,
            totalContributions: user.contributionsCollection.contributionCalendar.totalContributions,
            days: user.contributionsCollection.contributionCalendar.weeks.flatMap(\.contributionDays)
        )
    }

    private static let contributionCalendarQuery = """
    query ContributionCalendar($username: String!, $from: DateTime!, $to: DateTime!) {
      user(login: $username) {
        login
        contributionsCollection(from: $from, to: $to) {
          contributionCalendar {
            totalContributions
            weeks {
              contributionDays {
                date
                contributionCount
              }
            }
          }
        }
      }
    }
    """
}

private struct GraphQLRequest: Encodable {
    let query: String
    let variables: GraphQLVariables
}

private struct GraphQLVariables: Encodable {
    let username: String
    let from: String
    let to: String
}

private struct GraphQLResponse: Decodable {
    let data: GraphQLData?
    let errors: [GraphQLError]?
}

private struct GraphQLError: Decodable {
    let message: String
}

private struct GraphQLData: Decodable {
    let user: GraphQLUser?
}

private struct GraphQLUser: Decodable {
    let login: String
    let contributionsCollection: ContributionsCollection
}

private struct ContributionsCollection: Decodable {
    let contributionCalendar: ContributionCalendar
}

private struct ContributionCalendar: Decodable {
    let totalContributions: Int
    let weeks: [ContributionWeek]
}

private struct ContributionWeek: Decodable {
    let contributionDays: [ContributionDay]
}

extension ContributionDay: Decodable {
    enum CodingKeys: String, CodingKey {
        case date
        case count = "contributionCount"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateString = try container.decode(String.self, forKey: .date)
        guard let date = DateFormatter.githubDay.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Invalid GitHub contribution day.")
        }

        self.init(date: date, count: try container.decode(Int.self, forKey: .count))
    }
}

private extension Date {
    var iso8601String: String {
        ISO8601DateFormatter.githubDateTime.string(from: self)
    }
}

private extension JSONDecoder {
    static var github: JSONDecoder {
        JSONDecoder()
    }
}

private extension DateFormatter {
    static let githubDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private extension ISO8601DateFormatter {
    static let githubDateTime: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
