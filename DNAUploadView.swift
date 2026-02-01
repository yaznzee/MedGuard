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
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 70))
                            .foregroundColor(AppTheme.navy)
                        
                        Text("DNA Profile")
                            .font(AppFont.display(34))
                            .foregroundColor(AppTheme.navy)
                        
                        Text("Upload your 23andMe raw data file to analyze genetic drug interactions")
                            .font(AppFont.body(15))
                            .foregroundColor(AppTheme.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Current status
                    if let dnaProfile = appState.dnaProfile {
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.success)
                                    .font(.title)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("DNA Data Loaded")
                                        .font(AppFont.body(16, weight: .semibold))
                                        .foregroundColor(AppTheme.ink)
                                    
                                    Text("Uploaded: \(dnaProfile.uploadDate.formatted(date: .abbreviated, time: .shortened))")
                                        .font(AppFont.body(12))
                                        .foregroundColor(AppTheme.muted)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(AppTheme.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                            
                            // Genetic profile summary
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Detected Genes:")
                                    .font(AppFont.body(16, weight: .semibold))
                                    .foregroundColor(AppTheme.ink)
                                
                                ForEach(Array(dnaProfile.cytochromeData.sorted(by: { $0.key < $1.key })), id: \.key) { gene, genotype in
                                    HStack {
                                        Text(gene)
                                            .font(AppFont.mono(14))
                                            .foregroundColor(AppTheme.navy)
                                        
                                        Spacer()
                                        
                                        Text(genotype)
                                            .font(AppFont.mono(14))
                                            .foregroundColor(AppTheme.success)
                                    }
                                }
                            }
                            .padding()
                            .background(AppTheme.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
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
                            }
                        }
                        .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.navy))
                        
                        Text("Supported formats: .txt, .zip")
                            .font(AppFont.body(12))
                            .foregroundColor(AppTheme.muted)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText, .text, .zip],
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
                            .font(AppFont.body(16, weight: .semibold))
                    }
                    .padding(40)
                    .background(AppTheme.navy)
                    .cornerRadius(20)
                }
            }
        }
    }
    
    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    // Start accessing security-scoped resource within the async scope
                    guard url.startAccessingSecurityScopedResource() else {
                        await MainActor.run {
                            errorMessage = "Unable to access the selected file"
                            showingError = true
                        }
                        return
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // Upload DNA data
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
                .foregroundColor(AppTheme.navy)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(AppFont.body(16, weight: .semibold))
                    .foregroundColor(AppTheme.ink)
                
                Text(description)
                    .font(AppFont.body(14))
                    .foregroundColor(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
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

#Preview {
    NavigationView {
        DNAUploadView(appState: AppState())
    }
}
