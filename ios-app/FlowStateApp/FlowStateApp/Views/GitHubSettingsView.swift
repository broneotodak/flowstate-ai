import SwiftUI

struct GitHubSettingsView: View {
    @ObservedObject var viewModel: FlowStateViewModel
    @State private var githubToken = UserDefaults.standard.string(forKey: "github_token") ?? ""
    @State private var isTestingConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    @Environment(\.dismiss) private var dismiss
    
    enum ConnectionStatus {
        case unknown, testing, success, failed
        
        var color: Color {
            switch self {
            case .unknown: return .secondary
            case .testing: return .blue
            case .success: return .green
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .testing: return "arrow.triangle.2.circlepath"
            case .success: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var message: String {
            switch self {
            case .unknown: return "Enter your GitHub token to test connection"
            case .testing: return "Testing connection..."
            case .success: return "Successfully connected to GitHub!"
            case .failed: return "Failed to connect. Check your token."
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GitHub Personal Access Token")
                            .font(.headline)
                        
                        SecureField("Enter your GitHub token", text: $githubToken)
                            .textFieldStyle(.roundedBorder)
                        
                        // Connection Status
                        HStack {
                            Image(systemName: connectionStatus.icon)
                                .foregroundColor(connectionStatus.color)
                                .scaleEffect(connectionStatus == .testing ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), 
                                         value: connectionStatus == .testing)
                            
                            Text(connectionStatus.message)
                                .font(.caption)
                                .foregroundColor(connectionStatus.color)
                        }
                        .padding(.top, 4)
                        
                        // Test Connection Button
                        Button("Test Connection") {
                            testConnection()
                        }
                        .disabled(githubToken.isEmpty || isTestingConnection)
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Authentication")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To create a GitHub Personal Access Token:")
                        Text("1. Go to GitHub.com → Settings → Developer settings")
                        Text("2. Click 'Personal access tokens' → 'Tokens (classic)'")
                        Text("3. Generate new token with 'repo' permissions")
                        Text("4. Copy and paste the token above")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "eye.slash")
                                .foregroundColor(.blue)
                            Text("Security")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text("Your GitHub token is stored securely on your device and only used to fetch your repository data. It is never transmitted to third parties.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.green)
                            Text("Permissions")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text("FlowState only needs 'repo' access to read your commit history and repository information. No write access is required.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Privacy & Security")
                }
            }
            .navigationTitle("GitHub Integration")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                #if os(iOS)
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveToken()
                    }
                    .disabled(githubToken.isEmpty)
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveToken()
                    }
                    .disabled(githubToken.isEmpty)
                }
                #endif
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = .testing
        
        // Temporarily save token for testing
        UserDefaults.standard.set(githubToken, forKey: "github_token")
        
        Task {
            let service = GitHubService()
            let isValid = await service.validateGitHubToken()
            
            await MainActor.run {
                connectionStatus = isValid ? .success : .failed
                isTestingConnection = false
                
                if isValid {
                    // Update the main view model
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
    }
    
    private func saveToken() {
        UserDefaults.standard.set(githubToken, forKey: "github_token")
        
        // Refresh the main view model to pick up the new token
        Task {
            await viewModel.refresh()
        }
        
        dismiss()
    }
}

struct GitHubSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GitHubSettingsView(viewModel: FlowStateViewModel())
    }
}
