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
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.crimson)
                            
                            Text("MedGuard")
                                .font(AppFont.display(42))
                                .foregroundColor(AppTheme.navy)
                            
                            Text("Personalized Drug Safety Analysis")
                                .font(AppFont.body(15))
                                .foregroundColor(AppTheme.muted)
                        }
                        .padding(.top, 40)
                        
                        // Main workflow sections
                        VStack(spacing: 20) {
                            // Step 1: Upload DNA Data
                            WorkflowCard(
                                title: "1. Upload DNA Data",
                                subtitle: "Import your 23andMe report",
                                icon: "doc.text.fill",
                                color: AppTheme.navy,
                                isComplete: appState.dnaDataUploaded
                            ) {
                                NavigationLink(destination: DNAUploadView(appState: appState)) {
                                    Text("Upload DNA Report")
                                }
                                .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.navy))
                            }
                            
                            // Step 2: Enter Medications
                            WorkflowCard(
                                title: "2. Enter Medications",
                                subtitle: "List drugs you're taking or considering",
                                icon: "pills.fill",
                                color: AppTheme.ink,
                                isComplete: appState.medicationsEntered
                            ) {
                                NavigationLink(destination: MedicationInputView(appState: appState)) {
                                    Text("Enter Medications")
                                }
                                .buttonStyle(SecondaryActionButtonStyle(color: AppTheme.ink))
                            }
                            
                            // Step 3: Baseline Vitals
                            WorkflowCard(
                                title: "3. Record Baseline Vitals",
                                subtitle: "30-second measurement using camera",
                                icon: "waveform.path.ecg",
                                color: AppTheme.crimson,
                                isComplete: appState.baselineVitalsRecorded
                            ) {
                                NavigationLink(destination: VitalsMonitorView(appState: appState, isBaseline: true)) {
                                    Text("Measure Baseline")
                                }
                                .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.crimson))
                            }
                            
                            // Step 4: Get Analysis
                            if appState.canAnalyze {
                                WorkflowCard(
                                    title: "4. Safety Analysis",
                                    subtitle: "AI-powered interaction report",
                                    icon: "chart.bar.doc.horizontal.fill",
                                    color: AppTheme.navy,
                                    isComplete: false
                                ) {
                                    NavigationLink(destination: AnalysisResultsView(appState: appState)) {
                                        Text("Analyze Interactions")
                                    }
                                    .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.navy))
                                }
                            }
                            
                            // Step 5: Follow-up Monitoring (if yellow/red)
                            if appState.needsMonitoring {
                                WorkflowCard(
                                    title: "5. Monitor Symptoms",
                                    subtitle: "Track vitals after taking medication",
                                    icon: "bell.badge.fill",
                                    color: AppTheme.crimson,
                                    isComplete: false
                                ) {
                                    NavigationLink(destination: VitalsMonitorView(appState: appState, isBaseline: false)) {
                                        Text("Monitor Now")
                                    }
                                    .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.crimson))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Quick stats if data exists
                        if appState.hasAnyData {
                            VStack(spacing: 15) {
                                Text("Your Profile")
                                    .font(AppFont.display(22))
                                    .foregroundColor(AppTheme.navy)
                                
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
        HStack(spacing: 0) {
            Rectangle()
                .fill(color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppFont.body(17, weight: .semibold))
                            .foregroundColor(AppTheme.ink)
                        
                        Text(subtitle)
                            .font(AppFont.body(13))
                            .foregroundColor(AppTheme.muted)
                    }
                    
                    Spacer()
                    
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.success)
                            .font(.title2)
                    }
                }
                
                content
            }
            .padding(20)
        }
        .background(AppTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
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
                .foregroundColor(AppTheme.crimson)
            
            Text(value)
                .font(AppFont.display(22))
                .foregroundColor(AppTheme.ink)
            
            Text(label)
                .font(AppFont.body(12))
                .foregroundColor(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}
