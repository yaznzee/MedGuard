// ContentView.swift
// Main app view for Hack@Brown 2026 - Drug Interaction Analyzer
// Integrates Presage SDK for vitals monitoring

import SwiftUI
import AVFoundation
import SmartSpectraSwiftSDK

struct ContentView: View {
    @StateObject private var appState = AppState()
    @ObservedObject var sdk = SmartSpectraSwiftSDK.shared
    
    init() {
        // Configure Presage SDK
        let apiKey = "YOUR_PRESAGE_API_KEY_HERE"  // Get from https://physiology.presagetech.com
        sdk.setApiKey(apiKey)
        sdk.setSmartSpectraMode(.spot)  // Single measurement mode
        sdk.setMeasurementDuration(30.0)  // 30 second baseline measurement
        sdk.setCameraPosition(.front)
        sdk.setRecordingDelay(3)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("MedGuard")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Personalized Drug Safety Analysis")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 40)
                        
                        // Main workflow sections
                        VStack(spacing: 20) {
                            // Step 1: Upload DNA Data
                            WorkflowCard(
                                title: "1. Upload DNA Data",
                                subtitle: "Import your 23andMe report",
                                icon: "doc.text.fill",
                                color: Color(hex: "4facfe"),
                                isComplete: appState.dnaDataUploaded
                            ) {
                                NavigationLink(destination: DNAUploadView(appState: appState)) {
                                    Text("Upload DNA Report")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(hex: "4facfe"))
                                        .cornerRadius(12)
                                }
                            }
                            
                            // Step 2: Enter Medications
                            WorkflowCard(
                                title: "2. Enter Medications",
                                subtitle: "List drugs you're taking or considering",
                                icon: "pills.fill",
                                color: Color(hex: "43e97b"),
                                isComplete: appState.medicationsEntered
                            ) {
                                NavigationLink(destination: MedicationInputView(appState: appState)) {
                                    Text("Enter Medications")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(hex: "43e97b"))
                                        .cornerRadius(12)
                                }
                            }
                            
                            // Step 3: Baseline Vitals
                            WorkflowCard(
                                title: "3. Record Baseline Vitals",
                                subtitle: "30-second measurement using camera",
                                icon: "waveform.path.ecg",
                                color: Color(hex: "fa709a"),
                                isComplete: appState.baselineVitalsRecorded
                            ) {
                                NavigationLink(destination: VitalsMonitorView(appState: appState, isBaseline: true)) {
                                    Text("Measure Baseline")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(hex: "fa709a"))
                                        .cornerRadius(12)
                                }
                            }
                            
                            // Step 4: Get Analysis
                            if appState.canAnalyze {
                                WorkflowCard(
                                    title: "4. Safety Analysis",
                                    subtitle: "AI-powered interaction report",
                                    icon: "chart.bar.doc.horizontal.fill",
                                    color: Color(hex: "fee140"),
                                    isComplete: false
                                ) {
                                    NavigationLink(destination: AnalysisResultsView(appState: appState)) {
                                        Text("Analyze Interactions")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color(hex: "fa709a"))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            
                            // Step 5: Follow-up Monitoring (if yellow/red)
                            if appState.needsMonitoring {
                                WorkflowCard(
                                    title: "5. Monitor Symptoms",
                                    subtitle: "Track vitals after taking medication",
                                    icon: "bell.badge.fill",
                                    color: Color(hex: "ff6b6b"),
                                    isComplete: false
                                ) {
                                    NavigationLink(destination: VitalsMonitorView(appState: appState, isBaseline: false)) {
                                        Text("Monitor Now")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color(hex: "ff6b6b"))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Quick stats if data exists
                        if appState.hasAnyData {
                            VStack(spacing: 15) {
                                Text("Your Profile")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 15) {
                                    StatCard(
                                        value: "\(appState.medications.count)",
                                        label: "Medications",
                                        icon: "pills.fill"
                                    )
                                    
                                    if let vitals = appState.baselineVitals {
                                        StatCard(
                                            value: "\(vitals.heartRate)",
                                            label: "HR (BPM)",
                                            icon: "heart.fill"
                                        )
                                        
                                        StatCard(
                                            value: "\(vitals.breathingRate)",
                                            label: "BR (BPM)",
                                            icon: "lungs.fill"
                                        )
                                    }
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Supporting Views

struct WorkflowCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isComplete: Bool
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            content
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
