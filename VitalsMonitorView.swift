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
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text(isBaseline ? "Baseline Vitals" : "Follow-up Monitoring")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Text(isBaseline ? "Record your vitals before taking medication" : "Monitor for changes after medication")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Presage SDK View
                SmartSpectraView()
                    .frame(maxHeight: 400)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    .padding()
                
                // Current vitals display
                if let metrics = sdk.metricsBuffer {
                    VStack(spacing: 15) {
                        HStack(spacing: 30) {
                            VitalReadout(
                                icon: "heart.fill",
                                label: "Heart Rate",
                                value: "\(Int(metrics.pulse.strict.value))",
                                unit: "BPM",
                                color: .red,
                                isValid: metrics.pulse.strict.value > 0
                            )
                            
                            VitalReadout(
                                icon: "lungs.fill",
                                label: "Breathing Rate",
                                value: "\(Int(metrics.breathing.strict.value))",
                                unit: "BPM",
                                color: .blue,
                                isValid: metrics.breathing.strict.value > 0
                            )
                        }
                        
                        // Status indicator
                        HStack {
                            Image(systemName: processor.statusHint.contains("Hold") ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundColor(processor.statusHint.contains("Hold") ? .yellow : .green)
                            
                            Text(processor.statusHint)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Save button (appears after measurement)
                if let metrics = sdk.metricsBuffer,
                   metrics.pulse.strict.value > 0 && metrics.breathing.strict.value > 0 {
                    
                    Button(action: saveVitals) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Vitals")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
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
        }
    }
    
    func saveVitals() {
        guard let metrics = sdk.metricsBuffer else { return }
        
        let vitalsData = VitalsData(
            heartRate: Int(metrics.pulse.strict.value),
            breathingRate: Int(metrics.breathing.strict.value),
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
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(isValid ? value : "--")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isValid {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Image(systemName: "hourglass")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        VitalsMonitorView(appState: AppState(), isBaseline: true)
    }
}
