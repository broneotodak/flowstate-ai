import Foundation
import SwiftUI

// MARK: - GitHub API Service
@MainActor
class GitHubService: ObservableObject {
    private let baseURL = "https://api.github.com"
    private let username = "broneotodak" // Your GitHub username
    
    // GitHub Personal Access Token - Should be stored securely
    // For now, we'll fetch it from environment or UserDefaults
    private var githubToken: String {
        return UserDefaults.standard.string(forKey: "github_token") ?? ""
    }
    
    // MARK: - Fetch Recent Repositories
    func fetchRecentRepositories() async throws -> [GitHubRepository] {
        let url = URL(string: "\(baseURL)/user/repos?sort=updated&per_page=10")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(githubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GitHubError.apiError("Failed to fetch repositories")
        }
        
        let repositories = try JSONDecoder().decode([GitHubRepositoryResponse].self, from: data)
        return repositories.map { $0.toModel() }
    }
    
    // MARK: - Fetch Recent Commits for Repository
    func fetchRecentCommits(for repository: String) async throws -> [GitActivity] {
        let url = URL(string: "\(baseURL)/repos/\(username)/\(repository)/commits?per_page=20")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(githubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GitHubError.apiError("Failed to fetch commits for \(repository)")
        }
        
        let commits = try JSONDecoder().decode([GitHubCommitResponse].self, from: data)
        return commits.map { $0.toGitActivity(repository: repository) }
    }
    
    // MARK: - Fetch All Recent Git Activities
    func fetchAllRecentGitActivities() async throws -> [GitActivity] {
        // First get recent repositories
        let repositories = try await fetchRecentRepositories()
        
        var allActivities: [GitActivity] = []
        
        // Fetch commits from top 5 most recently updated repositories
        for repository in repositories.prefix(5) {
            do {
                let commits = try await fetchRecentCommits(for: repository.name)
                allActivities.append(contentsOf: commits.prefix(5)) // Top 5 commits per repo
            } catch {
                print("Failed to fetch commits for \(repository.name): \(error)")
                // Continue with other repositories
            }
        }
        
        // Sort by timestamp and return most recent 15 activities
        return Array(allActivities.sorted { $0.timestamp > $1.timestamp }.prefix(15))
    }
    
    // MARK: - Check GitHub Token Validity
    func validateGitHubToken() async -> Bool {
        guard !githubToken.isEmpty else { return false }
        
        let url = URL(string: "\(baseURL)/user")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(githubToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - GitHub API Response Models
private struct GitHubRepositoryResponse: Codable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let isPrivate: Bool
    let language: String?
    let stargazersCount: Int
    let forksCount: Int
    let updatedAt: String
    let htmlUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case fullName = "full_name"
        case isPrivate = "private"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case updatedAt = "updated_at"
        case htmlUrl = "html_url"
    }
    
    func toModel() -> GitHubRepository {
        let dateFormatter = ISO8601DateFormatter()
        let lastUpdated = dateFormatter.date(from: updatedAt) ?? Date()
        
        return GitHubRepository(
            id: String(id),
            name: name,
            fullName: fullName,
            description: description,
            isPrivate: isPrivate,
            language: language,
            stars: stargazersCount,
            forks: forksCount,
            lastUpdated: lastUpdated,
            url: htmlUrl
        )
    }
}

private struct GitHubCommitResponse: Codable {
    let sha: String
    let commit: CommitDetails
    let author: CommitAuthor?
    let stats: CommitStats?
    
    struct CommitDetails: Codable {
        let message: String
        let author: AuthorDetails
        
        struct AuthorDetails: Codable {
            let name: String
            let email: String
            let date: String
        }
    }
    
    struct CommitAuthor: Codable {
        let login: String
    }
    
    struct CommitStats: Codable {
        let additions: Int
        let deletions: Int
        let total: Int
    }
    
    func toGitActivity(repository: String) -> GitActivity {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.date(from: commit.author.date) ?? Date()
        
        return GitActivity(
            id: sha,
            repository: repository,
            branch: "main", // Default branch, could be enhanced to detect actual branch
            commitMessage: commit.message,
            author: author?.login ?? commit.author.name,
            timestamp: timestamp,
            type: .commit,
            additions: stats?.additions,
            deletions: stats?.deletions,
            files_changed: nil // Would need separate API call to get file count
        )
    }
}

// MARK: - GitHub Error Types
enum GitHubError: LocalizedError {
    case apiError(String)
    case invalidToken
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return message
        case .invalidToken:
            return "Invalid GitHub token. Please check your credentials."
        case .rateLimitExceeded:
            return "GitHub API rate limit exceeded. Please try again later."
        }
    }
}
