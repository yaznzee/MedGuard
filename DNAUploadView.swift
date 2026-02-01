// DNAUploadView.swift
// View for uploading 23andMe DNA data

import SwiftUI
import UniformTypeIdentifiers

struct DNAUploadView: View {
    @ObservedObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingFilePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                        
                        Text("DNA Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Upload your 23andMe raw data file to analyze genetic drug interactions")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Current status
                    if let dnaProfile = appState.dnaProfile {
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("DNA Data Loaded")
                                        .font(.headline)
                                    
                                    Text("Uploaded: \(dnaProfile.uploadDate.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            // Genetic profile summary
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Detected Genes:")
                                    .font(.headline)
                                
                                ForEach(Array(dnaProfile.cytochromeData.sorted(by: { $0.key < $1.key })), id: \.key) { gene, genotype in
                                    HStack {
                                        Text(gene)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                        
                                        Text(genotype)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    } else {
                        // Instructions
                        VStack(alignment: .leading, spacing: 15) {
                            InfoCard(
                                icon: "1.circle.fill",
                                title: "Download Your Data",
                                description: "Log into 23andMe.com and download your raw genetic data file"
                            )
                            
                            InfoCard(
                                icon: "2.circle.fill",
                                title: "Select File",
                                description: "Tap the upload button below and select your downloaded .txt or .zip file"
                            )
                            
                            InfoCard(
                                icon: "3.circle.fill",
                                title: "Analyze",
                                description: "We'll extract key cytochrome P450 genes that affect drug metabolism"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 30)
                    
                    // Upload button
                    VStack(spacing: 15) {
                        Button(action: {
                            showingFilePicker = true
                        }) {
                            HStack {
                                Image(systemName: appState.dnaProfile == nil ? "arrow.up.doc.fill" : "arrow.triangle.2.circlepath")
                                Text(appState.dnaProfile == nil ? "Upload DNA File" : "Upload New File")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color(hex: "4facfe"))
                            .cornerRadius(12)
                        }
                        
                        Text("Supported formats: .txt, .zip")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.text, .zip],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Upload Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
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
                        
                        Text("Processing DNA data...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(40)
                    .background(Color(hex: "4facfe"))
                    .cornerRadius(20)
                }
            }
        }
    }
    
    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Unable to access the selected file"
                showingError = true
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Upload DNA data
            Task {
                do {
                    try await appState.uploadDNAData(from: url)
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(Color(hex: "4facfe"))
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        DNAUploadView(appState: AppState())
    }
}
