import SwiftUI

struct HowItWorksView: View {
    @State private var selectedStep = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Text("🌊 FlowState AI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Intelligent Memory System for AI-Powered Development")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Stats Grid
                    StatsGridView()
                    
                    // Data Flow
                    DataFlowView()
                    
                    // How It Works Steps
                    VStack(spacing: 20) {
                        Text("How FlowState AI Works")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        ForEach(Array(workflowSteps.enumerated()), id: \.offset) { index, step in
                            WorkflowStepView(
                                step: step,
                                stepNumber: index + 1,
                                isSelected: selectedStep == index
                            )
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedStep = index
                                }
                            }
                        }
                    }
                    
                    // Architecture Components
                    ArchitectureGridView()
                    
                    // CTA Section
                    CTASection()
                }
                .padding()
            }
        }
        .navigationTitle("How It Works")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatsGridView: View {
    let stats = [
        StatItem(number: "2,675+", label: "Memories Stored"),
        StatItem(number: "5", label: "AI Tools Integrated"),
        StatItem(number: "3", label: "Platforms"),
        StatItem(number: "24/7", label: "Auto Tracking")
    ]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
            ForEach(stats, id: \.label) { stat in
                VStack(spacing: 5) {
                    Text(stat.number)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text(stat.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

struct DataFlowView: View {
    let flowItems = ["AI Tools", "pgVector DB", "Memory Bridge", "Activities", "FlowState App"]
    
    var body: some View {
        VStack(spacing: 15) {
            Text("🔄 Real-Time Memory Flow")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 10) {
                ForEach(Array(flowItems.enumerated()), id: \.offset) { index, item in
                    VStack {
                        Text(item)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(15)
                        
                        if index < flowItems.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
    }
}

struct WorkflowStepView: View {
    let step: WorkflowStep
    let stepNumber: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            // Step Number
            Circle()
                .fill(Color.blue)
                .frame(width: 35, height: 35)
                .overlay(
                    Text("\(stepNumber)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Step Content
            VStack(alignment: .leading, spacing: 8) {
                Text(step.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(step.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isSelected {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                        ForEach(step.tools, id: \.self) { tool in
                            Text(tool)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(10)
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct ArchitectureGridView: View {
    let components = [
        ArchComponent(
            icon: "🗄️",
            title: "Memory Sources",
            items: ["claude_desktop_memory", "context_embeddings", "activity_log", "flowstate_unified"]
        ),
        ArchComponent(
            icon: "🔧",
            title: "Automation Layer",
            items: ["Memory Bridge Daemon", "Git Hooks", "GitHub Webhooks", "Backup Scripts"]
        ),
        ArchComponent(
            icon: "📱",
            title: "User Interfaces",
            items: ["iOS App", "Web Dashboard", "Browser Extension", "Analytics"]
        ),
        ArchComponent(
            icon: "🔐",
            title: "Data Pipeline",
            items: ["Vector Embeddings", "Auto Categorization", "Real-time Sync", "Analytics"]
        )
    ]
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Architecture Components")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 15) {
                ForEach(components, id: \.title) { component in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(component.icon)
                                .font(.title2)
                            Text(component.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(component.items, id: \.self) { item in
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 4, height: 4)
                                    Text(item)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct CTASection: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("Experience FlowState AI")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Get instant visibility into your AI-powered development workflow")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 15) {
                Link(destination: URL(string: "https://apps.apple.com/app/flowstate-ai")!) {
                    HStack {
                        Image(systemName: "iphone")
                        Text("iOS App")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                
                Link(destination: URL(string: "https://flowstate.todak.ai")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Web Dashboard")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(25)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

// MARK: - Data Models
struct StatItem {
    let number: String
    let label: String
}

struct WorkflowStep {
    let title: String
    let description: String
    let tools: [String]
}

struct ArchComponent {
    let icon: String
    let title: String
    let items: [String]
}

// MARK: - Data
let workflowSteps = [
    WorkflowStep(
        title: "🤖 AI Tool Interactions",
        description: "Every time you use AI tools, they automatically save conversation memories and technical solutions to the pgVector database.",
        tools: ["Claude Desktop", "Claude Code CLI", "Cursor", "VS Code", "Browser Extension"]
    ),
    WorkflowStep(
        title: "🧠 Intelligent Memory Storage",
        description: "Memories are stored with vector embeddings for semantic search, project detection, and automatic categorization.",
        tools: ["pgVector Database", "OpenAI Embeddings", "CTK Compliance"]
    ),
    WorkflowStep(
        title: "🔄 Memory Bridge Automation",
        description: "The Memory Bridge daemon runs 24/7, automatically converting memories into activity logs with project detection.",
        tools: ["Node.js Daemon", "Project Detection", "30s Sync Interval"]
    ),
    WorkflowStep(
        title: "📱 Multi-Platform Display",
        description: "Activities appear instantly across all FlowState platforms - iOS app, web dashboard, and browser extension.",
        tools: ["iOS App", "Web Dashboard", "Browser Extension"]
    ),
    WorkflowStep(
        title: "☁️ Automated Backups",
        description: "All memories are automatically backed up to GitHub with encryption, ensuring your development history is never lost.",
        tools: ["GitHub Backups", "Cron Jobs", "Encrypted Storage"]
    )
]

#Preview {
    HowItWorksView()
}
