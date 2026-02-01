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
            LinearGradient(
                colors: [Color(hex: "43e97b"), Color(hex: "38f9d7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("Your Medications")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Add all medications you're taking or considering")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
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
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No medications added yet")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Tap the + button to add your first medication")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
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
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(Color(hex: "43e97b"))
                    .cornerRadius(12)
                }
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
                    .foregroundColor(Color(hex: "43e97b"))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(medication.dosage) • \(medication.frequency)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
