// AnalysisResultsView.swift
// View showing drug interaction analysis results

import SwiftUI

struct AnalysisResultsView: View {
    @ObservedObject var appState: AppState
    @State private var showingAnalysis = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "chart.bar.doc.horizontal.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.navy)
                        
                        Text("Safety Analysis")
                            .font(AppFont.display(34))
                            .foregroundColor(AppTheme.navy)
                        
                        if let analysis = appState.currentAnalysis {
                            Text("Completed \(analysis.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                .font(AppFont.body(14))
                                .foregroundColor(AppTheme.muted)
                        } else {
                            Text("Analyze your medication safety profile")
                                .font(AppFont.body(14))
                                .foregroundColor(AppTheme.muted)
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
                                .font(AppFont.body(16, weight: .semibold))
                                .foregroundColor(AppTheme.ink)
                            
                            Text(analysis.summary)
                                .font(AppFont.body(15))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(AppTheme.surface)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 8)
                        .padding(.horizontal)
                        
                        // Detailed Report
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Detailed Analysis", systemImage: "doc.text.fill")
                                .font(AppFont.body(16, weight: .semibold))
                                .foregroundColor(AppTheme.ink)
                            
                            Text(analysis.detailedReport)
                                .font(AppFont.body(15))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(AppTheme.surface)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 8)
                        .padding(.horizontal)
                        
                        // Gene-Drug Interactions
                        if !analysis.geneInteractions.isEmpty {
                            InteractionSection(
                                title: "Gene-Drug Interactions",
                                icon: "dna",
                                interactions: analysis.geneInteractions,
                                color: AppTheme.navy
                            )
                            .padding(.horizontal)
                        }
                        
                        // Drug-Drug Interactions
                        if !analysis.drugInteractions.isEmpty {
                            InteractionSection(
                                title: "Drug-Drug Interactions",
                                icon: "pills.circle.fill",
                                interactions: analysis.drugInteractions,
                                color: AppTheme.crimson
                            )
                            .padding(.horizontal)
                        }
                        
                        // Recommendations
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Recommendations", systemImage: "lightbulb.fill")
                                .font(AppFont.body(16, weight: .semibold))
                                .foregroundColor(AppTheme.ink)
                            
                            ForEach(Array(analysis.recommendations.enumerated()), id: \.offset) { index, recommendation in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(AppFont.body(16, weight: .semibold))
                                        .foregroundColor(AppTheme.navy)
                                    
                                    Text(recommendation)
                                        .font(AppFont.body(15))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding()
                        .background(AppTheme.surface)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 8)
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
                                            .font(AppFont.body(16, weight: .semibold))
                                            .foregroundColor(AppTheme.ink)
                                        
                                        if let timeRec = appState.monitoringTimeRecommendation {
                                            Text(timeRec)
                                                .font(AppFont.body(13))
                                                .foregroundColor(AppTheme.muted)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                
                                NavigationLink(destination: VitalsMonitorView(appState: appState, isBaseline: false)) {
                                    Text("Start Monitoring")
                                }
                                .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.warning))
                            }
                            .padding()
                            .background(AppTheme.surface)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 8)
                            .padding(.horizontal)
                        }
                        
                        // Share/Export button
                        Button(action: shareReport) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Report with Doctor")
                            }
                        }
                        .buttonStyle(SecondaryActionButtonStyle(color: AppTheme.navy))
                        .padding(.horizontal)
                        
                    } else {
                        // Pre-analysis view
                        VStack(spacing: 20) {
                            Image(systemName: "waveform.path.ecg.rectangle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(AppTheme.border)
                            
                            Text("Ready to Analyze")
                                .font(AppFont.display(26))
                                .foregroundColor(AppTheme.navy)
                            
                            Text("We'll analyze:\n- Your genetic profile\n- Drug-drug interactions\n- Gene-drug interactions\n- Your baseline vitals")
                                .font(AppFont.body(15))
                                .foregroundColor(AppTheme.muted)
                                .multilineTextAlignment(.center)
                            
                            Button(action: runAnalysis) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Run Analysis")
                                }
                            }
                            .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.navy))
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
        .alert("Analysis Error", isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { isPresented in
                if !isPresented { appState.errorMessage = nil }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.errorMessage ?? "Unknown error")
        }
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
                            .font(AppFont.body(16, weight: .semibold))
                        
                        Text("Powered by Gemini AI")
                            .foregroundColor(.white.opacity(0.8))
                            .font(AppFont.body(12))
                    }
                    .padding(40)
                    .background(AppTheme.navy)
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
        case .safe: return AppTheme.success
        case .caution: return AppTheme.warning
        case .danger: return AppTheme.danger
        case .unknown: return AppTheme.muted
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
                .font(AppFont.display(22))
                .foregroundColor(AppTheme.ink)
            
            Text(riskLevel.description)
                .font(AppFont.body(15))
                .foregroundColor(AppTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: backgroundColor.opacity(0.2), radius: 12, x: 0, y: 8)
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
                .font(AppFont.body(16, weight: .semibold))
                .foregroundColor(color)
            
            ForEach(Array(interactions.enumerated()), id: \.offset) { index, interaction in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(AppTheme.warning)
                    
                    Text(interaction)
                        .font(AppFont.body(15))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if index < interactions.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}

#Preview {
    NavigationView {
        AnalysisResultsView(appState: AppState())
    }
}
