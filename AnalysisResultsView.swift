// AnalysisResultsView.swift
// View showing drug interaction analysis results

import SwiftUI

struct AnalysisResultsView: View {
    @ObservedObject var appState: AppState
    @State private var showingAnalysis = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "chart.bar.doc.horizontal.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Safety Analysis")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let analysis = appState.currentAnalysis {
                            Text("Completed \(analysis.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        } else {
                            Text("Analyze your medication safety profile")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.top, 40)
                    
                    // Analysis content
                    if let analysis = appState.currentAnalysis {
                        // Risk level indicator (traffic light)
                        RiskLevelCard(riskLevel: analysis.riskLevel)
                            .padding(.horizontal)
                        
                        // AI Summary
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Summary", systemImage: "text.bubble.fill")
                                .font(.headline)
                            
                            Text(analysis.summary)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                        
                        // Detailed Report
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Detailed Analysis", systemImage: "doc.text.fill")
                                .font(.headline)
                            
                            Text(analysis.detailedReport)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                        
                        // Gene-Drug Interactions
                        if !analysis.geneInteractions.isEmpty {
                            InteractionSection(
                                title: "Gene-Drug Interactions",
                                icon: "dna",
                                interactions: analysis.geneInteractions,
                                color: Color(hex: "667eea")
                            )
                            .padding(.horizontal)
                        }
                        
                        // Drug-Drug Interactions
                        if !analysis.drugInteractions.isEmpty {
                            InteractionSection(
                                title: "Drug-Drug Interactions",
                                icon: "pills.circle.fill",
                                interactions: analysis.drugInteractions,
                                color: Color(hex: "fa709a")
                            )
                            .padding(.horizontal)
                        }
                        
                        // Recommendations
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Recommendations", systemImage: "lightbulb.fill")
                                .font(.headline)
                            
                            ForEach(Array(analysis.recommendations.enumerated()), id: \.offset) { index, recommendation in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .foregroundColor(Color(hex: "667eea"))
                                    
                                    Text(recommendation)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                        
                        // Monitoring recommendation
                        if appState.needsMonitoring {
                            VStack(spacing: 15) {
                                HStack {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Monitoring Recommended")
                                            .font(.headline)
                                        
                                        if let timeRec = appState.monitoringTimeRecommendation {
                                            Text(timeRec)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                
                                NavigationLink(destination: VitalsMonitorView(appState: appState, isBaseline: false)) {
                                    Text("Start Monitoring")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.orange)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10)
                            .padding(.horizontal)
                        }
                        
                        // Share/Export button
                        Button(action: shareReport) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Report with Doctor")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                    } else {
                        // Pre-analysis view
                        VStack(spacing: 20) {
                            Image(systemName: "waveform.path.ecg.rectangle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("Ready to Analyze")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("We'll analyze:\n• Your genetic profile\n• Drug-drug interactions\n• Gene-drug interactions\n• Your baseline vitals")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                            
                            Button(action: runAnalysis) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Run Analysis")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(Color(hex: "667eea"))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)
                        }
                        .padding(.top, 60)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if appState.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Analyzing interactions...")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Text("Powered by Gemini AI")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                    .padding(40)
                    .background(Color(hex: "667eea"))
                    .cornerRadius(20)
                }
            }
        }
    }
    
    func runAnalysis() {
        Task {
            do {
                try await appState.performAnalysis()
            } catch {
                print("Analysis error: \(error)")
            }
        }
    }
    
    func shareReport() {
        guard let analysis = appState.currentAnalysis else { return }
        
        let reportText = """
        MedGuard Drug Interaction Report
        Generated: \(analysis.timestamp.formatted())
        
        RISK LEVEL: \(analysis.riskLevel.rawValue.uppercased())
        
        SUMMARY:
        \(analysis.summary)
        
        DETAILED ANALYSIS:
        \(analysis.detailedReport)
        
        GENE-DRUG INTERACTIONS:
        \(analysis.geneInteractions.isEmpty ? "None detected" : analysis.geneInteractions.joined(separator: "\n"))
        
        DRUG-DRUG INTERACTIONS:
        \(analysis.drugInteractions.isEmpty ? "None detected" : analysis.drugInteractions.joined(separator: "\n"))
        
        RECOMMENDATIONS:
        \(analysis.recommendations.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [reportText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct RiskLevelCard: View {
    let riskLevel: RiskLevel
    
    var backgroundColor: Color {
        switch riskLevel {
        case .safe: return Color.green
        case .caution: return Color.yellow
        case .danger: return Color.red
        case .unknown: return Color.gray
        }
    }
    
    var iconName: String {
        switch riskLevel {
        case .safe: return "checkmark.shield.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .danger: return "xmark.octagon.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 70))
                .foregroundColor(backgroundColor)
            
            Text(riskLevel.rawValue.uppercased())
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(riskLevel.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: backgroundColor.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

struct InteractionSection: View {
    let title: String
    let icon: String
    let interactions: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(color)
            
            ForEach(Array(interactions.enumerated()), id: \.offset) { index, interaction in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    
                    Text(interaction)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if index < interactions.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
    }
}

#Preview {
    NavigationView {
        AnalysisResultsView(appState: AppState())
    }
}
