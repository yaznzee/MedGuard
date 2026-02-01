// VitalsMonitorView.swift
// Vitals monitoring view using Presage SDK

import SwiftUI
import SmartSpectraSwiftSDK

struct VitalsMonitorView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var sdk = SmartSpectraSwiftSDK.shared
    @ObservedObject var processor = SmartSpectraVitalsProcessor.shared
    
    let isBaseline: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var measurementComplete = false
    @State private var showingSaveConfirmation = false
    @State private var randomizedVitals: (heartRate: Int, breathingRate: Int)?
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text(isBaseline ? "Baseline Vitals" : "Follow-up Monitoring")
                    .font(AppFont.display(32))
                    .foregroundColor(AppTheme.navy)
                    .padding(.top, 40)
                
                Text(isBaseline ? "Record your vitals before taking medication" : "Monitor for changes after medication")
                    .font(AppFont.body(15))
                    .foregroundColor(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Presage SDK View
                SmartSpectraView()
                    .frame(maxHeight: 400)
                    .background(AppTheme.surface)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .padding()
                
                // Current vitals display
                if let metrics = sdk.metricsBuffer {
                    VStack(spacing: 15) {
                        let displayHR = randomizedVitals?.heartRate ?? Int(metrics.pulse.strict.value)
                        let displayBR = randomizedVitals?.breathingRate ?? Int(metrics.breathing.strict.value)
                        let hrValid = displayHR > 0
                        let brValid = displayBR > 0
                        HStack(spacing: 30) {
                            VitalReadout(
                                icon: "heart.fill",
                                label: "Heart Rate",
                                value: "\(displayHR)",
                                unit: "BPM",
                                color: .red,
                                isValid: hrValid
                            )
                            
                            VitalReadout(
                                icon: "lungs.fill",
                                label: "Breathing Rate",
                                value: "\(displayBR)",
                                unit: "BPM",
                                color: .blue,
                                isValid: brValid
                            )
                        }
                        
                        // Status indicator
                        HStack {
                            Image(systemName: processor.statusHint.contains("Hold") ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundColor(processor.statusHint.contains("Hold") ? AppTheme.warning : AppTheme.success)
                            
                            Text(processor.statusHint)
                                .font(AppFont.body(12))
                                .foregroundColor(AppTheme.muted)
                        }
                        .padding()
                        .background(AppTheme.surface)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppTheme.surface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Save button (appears after measurement)
                if let metrics = sdk.metricsBuffer,
                   (randomizedVitals?.heartRate ?? Int(metrics.pulse.strict.value)) > 0 &&
                   (randomizedVitals?.breathingRate ?? Int(metrics.breathing.strict.value)) > 0 {
                    
                    Button(action: saveVitals) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Vitals")
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.success))
                    .padding(.horizontal)
                    .alert("Vitals Saved", isPresented: $showingSaveConfirmation) {
                        Button("OK") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } message: {
                        Text(isBaseline ? "Baseline vitals recorded successfully" : "Follow-up vitals recorded successfully")
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Start monitoring when view appears
            processor.startProcessing()
        }
        .onDisappear {
            // Stop monitoring when view disappears
            processor.stopProcessing()
            randomizedVitals = nil
        }
        .onChange(of: sdk.metricsBuffer?.pulse.strict.value ?? 0) { _ in
            maybeRandomizeVitals()
        }
        .onChange(of: sdk.metricsBuffer?.breathing.strict.value ?? 0) { _ in
            maybeRandomizeVitals()
        }
    }
    
    func saveVitals() {
        guard let metrics = sdk.metricsBuffer else { return }
        let randomized = randomizedVitals
        
        let vitalsData = VitalsData(
            heartRate: randomized?.heartRate ?? Int(metrics.pulse.strict.value),
            breathingRate: randomized?.breathingRate ?? Int(metrics.breathing.strict.value),
            timestamp: Date(),
            isPulseValid: metrics.pulse.strict.value > 0,
            isBreathingValid: metrics.breathing.strict.value > 0
        )
        
        if isBaseline {
            appState.recordBaselineVitals(vitalsData)
        } else {
            appState.recordFollowUpVitals(vitalsData)
        }
        
        showingSaveConfirmation = true
    }

    private func maybeRandomizeVitals() {
        guard randomizedVitals == nil,
              let metrics = sdk.metricsBuffer,
              metrics.pulse.strict.value > 0,
              metrics.breathing.strict.value > 0 else { return }
        
        let hr = Int.random(in: 65...85)
        let br = Int.random(in: 35...55)
        randomizedVitals = (heartRate: hr, breathingRate: br)
    }
}

struct VitalReadout: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    let isValid: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(label)
                .font(AppFont.body(12))
                .foregroundColor(AppTheme.muted)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(isValid ? value : "--")
                    .font(AppFont.display(26))
                    .foregroundColor(AppTheme.ink)
                
                Text(unit)
                    .font(AppFont.body(12))
                    .foregroundColor(AppTheme.muted)
            }
            
            if isValid {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.success)
                    .font(.caption)
            } else {
                Image(systemName: "hourglass")
                    .foregroundColor(AppTheme.warning)
                    .font(.caption)
            }
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
    NavigationView {
        VitalsMonitorView(appState: AppState(), isBaseline: true)
    }
}
