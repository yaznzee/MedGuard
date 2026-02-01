// MedicationInputView.swift
// View for entering medications

import SwiftUI

struct MedicationInputView: View {
    @ObservedObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddSheet = false
    @State private var editingMedication: Medication?
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.navy)
                    
                    Text("Your Medications")
                        .font(AppFont.display(34))
                        .foregroundColor(AppTheme.navy)
                    
                    Text("Add all medications you're taking or considering")
                        .font(AppFont.body(15))
                        .foregroundColor(AppTheme.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal)
                
                // Medications list
                if appState.medications.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "pill.circle")
                            .font(.system(size: 80))
                            .foregroundColor(AppTheme.border)
                        
                        Text("No medications added yet")
                            .font(AppFont.body(16, weight: .semibold))
                            .foregroundColor(AppTheme.ink)
                        
                        Text("Tap the + button to add your first medication")
                            .font(AppFont.body(14))
                            .foregroundColor(AppTheme.muted)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(appState.medications) { medication in
                                MedicationCard(medication: medication)
                                    .contextMenu {
                                        Button(action: {
                                            editingMedication = medication
                                        }) {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            appState.removeMedication(medication)
                                        }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
                
                // Add button
                Button(action: {
                    showingAddSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Medication")
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.navy))
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSheet) {
            AddMedicationSheet(appState: appState)
        }
        .sheet(item: $editingMedication) { medication in
            EditMedicationSheet(appState: appState, medication: medication)
        }
    }
}

struct MedicationCard: View {
    let medication: Medication
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "pill.fill")
                    .foregroundColor(AppTheme.crimson)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(AppFont.body(16, weight: .semibold))
                        .foregroundColor(AppTheme.ink)
                    
                    Text("\(medication.dosage) - \(medication.frequency)")
                        .font(AppFont.body(14))
                        .foregroundColor(AppTheme.muted)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

struct AddMedicationSheet: View {
    @ObservedObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Once daily"
    
    let frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed", "Every other day", "Weekly"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Medication Details") {
                    TextField("Name (e.g., Aspirin)", text: $name)
                    TextField("Dosage (e.g., 81mg)", text: $dosage)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let medication = Medication(
                            name: name,
                            dosage: dosage,
                            frequency: frequency
                        )
                        appState.addMedication(medication)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
}

struct EditMedicationSheet: View {
    @ObservedObject var appState: AppState
    let medication: Medication
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = ""
    
    let frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed", "Every other day", "Weekly"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Medication Details") {
                    TextField("Name", text: $name)
                    TextField("Dosage", text: $dosage)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
                }
            }
            .navigationTitle("Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = Medication(
                            id: medication.id,
                            name: name,
                            dosage: dosage,
                            frequency: frequency
                        )
                        appState.updateMedication(updated)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
        .onAppear {
            name = medication.name
            dosage = medication.dosage
            frequency = medication.frequency
        }
    }
}

#Preview {
    NavigationView {
        MedicationInputView(appState: AppState())
    }
}
