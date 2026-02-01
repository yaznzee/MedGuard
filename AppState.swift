// AppState.swift
// Central state management for the MedGuard app

import Foundation
import Combine

// MARK: - Models

struct Medication: Identifiable, Codable {
    let id: UUID
    var name: String
    var dosage: String
    var frequency: String
    
    init(id: UUID = UUID(), name: String, dosage: String, frequency: String) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
    }
}

struct VitalsData: Codable {
    let heartRate: Int
    let breathingRate: Int
    let timestamp: Date
    let isPulseValid: Bool
    let isBreathingValid: Bool
    
    var isValid: Bool {
        isPulseValid && isBreathingValid
    }
}

struct DNAProfile: Codable {
    let cytochromeData: [String: String]  // Gene -> Genotype mapping
    let uploadDate: Date
    
    // Key cytochrome P450 genes for drug metabolism
    var cyp2d6: String? { cytochromeData["CYP2D6"] }
    var cyp2c19: String? { cytochromeData["CYP2C19"] }
    var cyp2c9: String? { cytochromeData["CYP2C9"] }
    var cyp3a4: String? { cytochromeData["CYP3A4"] }
    var cyp1a2: String? { cytochromeData["CYP1A2"] }
}

struct UserProfile: Codable {
    var age: Int?
    var sex: String?
    var weight: Double?  // kg
    var height: Double?  // cm
    var smokingStatus: String?
    var alcoholUse: String?
    var medicalConditions: [String]
    var allergies: [String]
    var surgeryHistory: [String]
    
    init() {
        self.medicalConditions = []
        self.allergies = []
        self.surgeryHistory = []
    }
}

enum RiskLevel: String, Codable {
    case safe = "green"
    case caution = "yellow"
    case danger = "red"
    case unknown = "gray"
    
    var color: String {
        rawValue
    }
    
    var description: String {
        switch self {
        case .safe:
            return "No significant interactions detected"
        case .caution:
            return "Potential interaction - monitoring recommended"
        case .danger:
            return "High risk interaction - consult physician immediately"
        case .unknown:
            return "Insufficient data for analysis"
        }
    }
}

struct AnalysisResult: Codable, Identifiable {
    let id: UUID
    let riskLevel: RiskLevel
    let summary: String
    let detailedReport: String
    let geneInteractions: [String]
    let drugInteractions: [String]
    let recommendations: [String]
    let timestamp: Date
    
    init(id: UUID = UUID(), riskLevel: RiskLevel, summary: String, detailedReport: String, 
         geneInteractions: [String], drugInteractions: [String], recommendations: [String], 
         timestamp: Date = Date()) {
        self.id = id
        self.riskLevel = riskLevel
        self.summary = summary
        self.detailedReport = detailedReport
        self.geneInteractions = geneInteractions
        self.drugInteractions = drugInteractions
        self.recommendations = recommendations
        self.timestamp = timestamp
    }
}

// MARK: - App State

class AppState: ObservableObject {
    // User data
    @Published var userProfile = UserProfile()
    @Published var dnaProfile: DNAProfile?
    @Published var medications: [Medication] = []
    
    // Vitals tracking
    @Published var baselineVitals: VitalsData?
    @Published var followUpVitals: [VitalsData] = []
    
    // Analysis results
    @Published var currentAnalysis: AnalysisResult?
    @Published var analysisHistory: [AnalysisResult] = []
    
    // Workflow state
    @Published var dnaDataUploaded: Bool = false
    @Published var medicationsEntered: Bool = false
    @Published var baselineVitalsRecorded: Bool = false
    @Published var analysisCompleted: Bool = false
    
    // UI state
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Backend API service
    private let apiService = BackendAPIService()
    
    init() {
        // Demo reset: start fresh every app launch.
        resetAll()
    }
    
    // MARK: - Computed Properties
    
    var canAnalyze: Bool {
        dnaDataUploaded && medicationsEntered && baselineVitalsRecorded
    }
    
    var needsMonitoring: Bool {
        guard let analysis = currentAnalysis else { return false }
        return analysis.riskLevel == .caution || analysis.riskLevel == .danger
    }
    
    var hasAnyData: Bool {
        dnaDataUploaded || !medications.isEmpty || baselineVitals != nil
    }
    
    var monitoringTimeRecommendation: String? {
        guard let analysis = currentAnalysis else { return nil }
        
        // Calculate when symptoms might appear based on drug half-life
        switch analysis.riskLevel {
        case .caution:
            return "Monitor vitals in 2-4 hours"
        case .danger:
            return "Monitor vitals immediately and every 30 minutes"
        default:
            return nil
        }
    }
    
    // MARK: - DNA Upload
    
    func uploadDNAData(from fileURL: URL) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Parse 23andMe file
            let dnaData = try parse23andMeFile(fileURL)
            
            // Upload to backend for processing
            let profile = try await apiService.uploadDNAProfile(dnaData)
            
            await MainActor.run {
                self.dnaProfile = profile
                self.dnaDataUploaded = true
                saveToUserDefaults()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to upload DNA data: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
    
    private func parse23andMeFile(_ url: URL) throws -> [String: String] {
        // Simple parser for 23andMe raw data format
        // Format: rsid, chromosome, position, genotype
        let content = try String(contentsOf: url)
        var cytochromeData: [String: String] = [:]
        
        // Known SNPs for major CYP genes
        let targetSNPs: [String: String] = [
            "rs1065852": "CYP2D6",
            "rs4244285": "CYP2C19",
            "rs1799853": "CYP2C9",
            "rs776746": "CYP3A5",
            "rs762551": "CYP1A2"
        ]
        
        for line in content.components(separatedBy: .newlines) {
            guard !line.hasPrefix("#"), !line.isEmpty else { continue }
            
            let components = line.components(separatedBy: "\t")
            guard components.count >= 4 else { continue }
            
            let rsid = components[0]
            let genotype = components[3]
            
            if let gene = targetSNPs[rsid] {
                cytochromeData[gene] = genotype
            }
        }
        
        return cytochromeData
    }
    
    // MARK: - Medication Management
    
    func addMedication(_ medication: Medication) {
        medications.append(medication)
        medicationsEntered = !medications.isEmpty
        saveToUserDefaults()
    }
    
    func removeMedication(_ medication: Medication) {
        medications.removeAll { $0.id == medication.id }
        medicationsEntered = !medications.isEmpty
        saveToUserDefaults()
    }
    
    func updateMedication(_ medication: Medication) {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
            saveToUserDefaults()
        }
    }
    
    // MARK: - Vitals Recording
    
    func recordBaselineVitals(_ vitals: VitalsData) {
        baselineVitals = vitals
        baselineVitalsRecorded = vitals.isValid
        saveToUserDefaults()
    }
    
    func recordFollowUpVitals(_ vitals: VitalsData) {
        followUpVitals.append(vitals)
        
        // Check for significant changes from baseline
        if let baseline = baselineVitals {
            let hrChange = abs(vitals.heartRate - baseline.heartRate)
            let brChange = abs(vitals.breathingRate - baseline.breathingRate)
            
            // Alert if vitals changed significantly
            if hrChange > 20 || brChange > 5 {
                errorMessage = "⚠️ Significant vital sign changes detected. Consider contacting your healthcare provider."
            }
        }
        
        saveToUserDefaults()
    }
    
    func compareVitals() -> String {
        guard let baseline = baselineVitals,
              let latest = followUpVitals.last else {
            return "Insufficient data"
        }
        
        let hrChange = latest.heartRate - baseline.heartRate
        let brChange = latest.breathingRate - baseline.breathingRate
        
        var report = "Vitals Comparison:\n\n"
        report += "Heart Rate: \(baseline.heartRate) → \(latest.heartRate) BPM"
        report += " (\(hrChange > 0 ? "+" : "")\(hrChange))\n"
        report += "Breathing Rate: \(baseline.breathingRate) → \(latest.breathingRate) BPM"
        report += " (\(brChange > 0 ? "+" : "")\(brChange))\n\n"
        
        if abs(hrChange) < 10 && abs(brChange) < 3 {
            report += "✅ Vitals remain stable"
        } else if abs(hrChange) < 20 && abs(brChange) < 5 {
            report += "⚠️ Moderate changes detected - continue monitoring"
        } else {
            report += "🚨 Significant changes - seek medical attention"
        }
        
        return report
    }
    
    // MARK: - Analysis
    
    func performAnalysis() async throws {
        guard canAnalyze else {
            throw AnalysisError.insufficientData
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await apiService.analyzeInteractions(
                dnaProfile: dnaProfile!,
                medications: medications,
                userProfile: userProfile,
                baselineVitals: baselineVitals!
            )
            
            await MainActor.run {
                self.currentAnalysis = result
                self.analysisHistory.append(result)
                self.analysisCompleted = true
                self.isLoading = false
                saveToUserDefaults()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Analysis failed: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - Persistence
    
    private func saveToUserDefaults() {
        // Save key data
        if let dnaProfile = dnaProfile,
           let data = try? JSONEncoder().encode(dnaProfile) {
            UserDefaults.standard.set(data, forKey: "dnaProfile")
        }
        
        if let medicationsData = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(medicationsData, forKey: "medications")
        }
        
        if let vitalsData = try? JSONEncoder().encode(baselineVitals) {
            UserDefaults.standard.set(vitalsData, forKey: "baselineVitals")
        }
        
        UserDefaults.standard.set(dnaDataUploaded, forKey: "dnaDataUploaded")
        UserDefaults.standard.set(medicationsEntered, forKey: "medicationsEntered")
        UserDefaults.standard.set(baselineVitalsRecorded, forKey: "baselineVitalsRecorded")
    }
    
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "dnaProfile"),
           let profile = try? JSONDecoder().decode(DNAProfile.self, from: data) {
            dnaProfile = profile
        }
        
        if let data = UserDefaults.standard.data(forKey: "medications"),
           let meds = try? JSONDecoder().decode([Medication].self, from: data) {
            medications = meds
        }
        
        if let data = UserDefaults.standard.data(forKey: "baselineVitals"),
           let vitals = try? JSONDecoder().decode(VitalsData.self, from: data) {
            baselineVitals = vitals
        }
        
        dnaDataUploaded = UserDefaults.standard.bool(forKey: "dnaDataUploaded")
        medicationsEntered = UserDefaults.standard.bool(forKey: "medicationsEntered")
        baselineVitalsRecorded = UserDefaults.standard.bool(forKey: "baselineVitalsRecorded")
    }
    
    func resetAll() {
        dnaProfile = nil
        medications = []
        baselineVitals = nil
        followUpVitals = []
        currentAnalysis = nil
        analysisHistory = []
        
        dnaDataUploaded = false
        medicationsEntered = false
        baselineVitalsRecorded = false
        analysisCompleted = false
        
        UserDefaults.standard.removeObject(forKey: "dnaProfile")
        UserDefaults.standard.removeObject(forKey: "medications")
        UserDefaults.standard.removeObject(forKey: "baselineVitals")
        UserDefaults.standard.removeObject(forKey: "dnaDataUploaded")
        UserDefaults.standard.removeObject(forKey: "medicationsEntered")
        UserDefaults.standard.removeObject(forKey: "baselineVitalsRecorded")
    }
}

// MARK: - Errors

enum AnalysisError: LocalizedError {
    case insufficientData
    case networkError
    case invalidResponse(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Please complete all steps before analysis"
        case .networkError:
            return "Network connection failed"
        case .invalidResponse(let statusCode, let message):
            return "Invalid response from server (HTTP \(statusCode)). \(message)"
        }
    }
}

// MARK: - Backend API Service

class BackendAPIService {
    private let baseURL = "http://localhost:3000/api"  // Change to your backend URL
    private let geminiAPIKey = "AIzaSyAg24n-YWgkJf8aka251yUPEkKTOLFBdiM"
    
    func uploadDNAProfile(_ cytochromeData: [String: String]) async throws -> DNAProfile {
        // In production, upload to your backend
        // For hackathon demo, we'll create it locally
        return DNAProfile(cytochromeData: cytochromeData, uploadDate: Date())
    }
    
    func analyzeInteractions(
        dnaProfile: DNAProfile,
        medications: [Medication],
        userProfile: UserProfile,
        baselineVitals: VitalsData
    ) async throws -> AnalysisResult {
        
        // Calculate activity score
        let activityScore = calculateActivityScore(dnaProfile: dnaProfile, userProfile: userProfile)
        
        // Check drug-drug interactions
        let ddiResults = await checkDrugDrugInteractions(medications: medications)
        
        // Check gene-drug interactions
        let gdiResults = checkGeneDrugInteractions(dnaProfile: dnaProfile, medications: medications)
        
        // Determine overall risk level
        let riskLevel = determineRiskLevel(ddi: ddiResults, gdi: gdiResults, activityScore: activityScore)
        
        // Generate AI summary using Gemini
        let aiSummary = try await generateGeminiSummary(
            dnaProfile: dnaProfile,
            medications: medications,
            userProfile: userProfile,
            activityScore: activityScore,
            ddiResults: ddiResults,
            gdiResults: gdiResults,
            riskLevel: riskLevel
        )
        
        return AnalysisResult(
            riskLevel: riskLevel,
            summary: aiSummary.summary,
            detailedReport: aiSummary.detailed,
            geneInteractions: gdiResults,
            drugInteractions: ddiResults,
            recommendations: aiSummary.recommendations,
            timestamp: Date()
        )
    }
    
    private func calculateActivityScore(dnaProfile: DNAProfile, userProfile: UserProfile) -> Double {
        var score: Double = 1.0  // Normal metabolism baseline
        
        // CYP2D6 variants (affects 25% of drugs)
        if let cyp2d6 = dnaProfile.cyp2d6 {
            switch cyp2d6 {
            case "TT": score *= 0.5  // Poor metabolizer
            case "CT": score *= 0.75 // Intermediate
            case "CC": score *= 1.0  // Normal
            default: break
            }
        }
        
        // CYP2C19 variants (affects PPIs, antidepressants)
        if let cyp2c19 = dnaProfile.cyp2c19 {
            switch cyp2c19 {
            case "AA": score *= 0.5  // Poor metabolizer
            case "AG": score *= 0.75 // Intermediate
            case "GG": score *= 1.0  // Normal
            default: break
            }
        }
        
        // Age factor (metabolism slows with age)
        if let age = userProfile.age {
            if age > 65 {
                score *= 0.8
            } else if age < 18 {
                score *= 1.1
            }
        }
        
        // Sex factor (some enzymes differ)
        if userProfile.sex == "Female" {
            score *= 0.95  // Slightly slower for some enzymes
        }
        
        // Smoking increases CYP1A2 activity
        if userProfile.smokingStatus == "Current smoker" {
            score *= 1.2
        }
        
        // Alcohol affects liver function
        if userProfile.alcoholUse == "Heavy" {
            score *= 0.85
        }
        
        return score
    }
    
    private func checkDrugDrugInteractions(medications: [Medication]) async -> [String] {
        // In production, query DrugBank or similar database
        // For demo, we'll use simplified logic
        var interactions: [String] = []
        
        let knownInteractions: [String: [String]] = [
            "warfarin": ["aspirin", "ibuprofen", "naproxen"],
            "metformin": ["alcohol"],
            "simvastatin": ["grapefruit", "amlodipine"],
            "ssri": ["tramadol", "triptans"],
            "ace inhibitor": ["potassium supplements", "nsaids"]
        ]
        
        for (index, med1) in medications.enumerated() {
            for med2 in medications.dropFirst(index + 1) {
                let name1 = med1.name.lowercased()
                let name2 = med2.name.lowercased()
                
                for (drug, interactsWith) in knownInteractions {
                    if name1.contains(drug) && interactsWith.contains(where: { name2.contains($0) }) {
                        interactions.append("\(med1.name) + \(med2.name): Increased bleeding risk")
                    }
                    if name2.contains(drug) && interactsWith.contains(where: { name1.contains($0) }) {
                        interactions.append("\(med2.name) + \(med1.name): Increased bleeding risk")
                    }
                }
            }
        }
        
        return interactions
    }
    
    private func checkGeneDrugInteractions(dnaProfile: DNAProfile, medications: [Medication]) -> [String] {
        var interactions: [String] = []
        
        for med in medications {
            let medName = med.name.lowercased()
            
            // CYP2D6 substrates
            if let cyp2d6 = dnaProfile.cyp2d6, cyp2d6 == "TT" {
                if medName.contains("codeine") || medName.contains("tramadol") {
                    interactions.append("\(med.name): Poor CYP2D6 metabolizer - reduced effectiveness")
                }
                if medName.contains("metoprolol") || medName.contains("carvedilol") {
                    interactions.append("\(med.name): Poor CYP2D6 metabolizer - increased side effects risk")
                }
            }
            
            // CYP2C19 substrates
            if let cyp2c19 = dnaProfile.cyp2c19, cyp2c19 == "AA" {
                if medName.contains("clopidogrel") {
                    interactions.append("\(med.name): Poor CYP2C19 metabolizer - reduced effectiveness")
                }
                if medName.contains("omeprazole") || medName.contains("esomeprazole") {
                    interactions.append("\(med.name): Poor CYP2C19 metabolizer - may need dose adjustment")
                }
            }
            
            // CYP2C9 substrates
            if let cyp2c9 = dnaProfile.cyp2c9, cyp2c9 != "CC" {
                if medName.contains("warfarin") {
                    interactions.append("\(med.name): CYP2C9 variant - requires careful dose monitoring")
                }
            }
        }
        
        return interactions
    }
    
    private func determineRiskLevel(ddi: [String], gdi: [String], activityScore: Double) -> RiskLevel {
        let totalInteractions = ddi.count + gdi.count
        
        // High risk if many interactions or extreme activity score
        if totalInteractions >= 3 || activityScore < 0.5 || activityScore > 1.5 {
            return .danger
        }
        
        // Moderate risk if some interactions
        if totalInteractions >= 1 || activityScore < 0.7 || activityScore > 1.3 {
            return .caution
        }
        
        // Safe if no interactions and normal activity
        if totalInteractions == 0 && activityScore >= 0.8 && activityScore <= 1.2 {
            return .safe
        }
        
        return .unknown
    }
    
    private func generateGeminiSummary(
        dnaProfile: DNAProfile,
        medications: [Medication],
        userProfile: UserProfile,
        activityScore: Double,
        ddiResults: [String],
        gdiResults: [String],
        riskLevel: RiskLevel
    ) async throws -> (summary: String, detailed: String, recommendations: [String]) {
        
        // Construct prompt for Gemini
        let prompt = """
        You are a clinical pharmacogenomics expert. Analyze this patient's drug interaction profile:
        
        PATIENT PROFILE:
        - Age: \(userProfile.age ?? 0)
        - Sex: \(userProfile.sex ?? "Unknown")
        - Medical Conditions: \(userProfile.medicalConditions.joined(separator: ", "))
        
        MEDICATIONS:
        \(medications.map { "- \($0.name) (\($0.dosage), \($0.frequency))" }.joined(separator: "\n"))
        
        GENETIC PROFILE:
        - CYP2D6: \(dnaProfile.cyp2d6 ?? "Unknown")
        - CYP2C19: \(dnaProfile.cyp2c19 ?? "Unknown")
        - CYP2C9: \(dnaProfile.cyp2c9 ?? "Unknown")
        - Metabolic Activity Score: \(String(format: "%.2f", activityScore))
        
        DRUG-DRUG INTERACTIONS:
        \(ddiResults.isEmpty ? "None detected" : ddiResults.joined(separator: "\n"))
        
        GENE-DRUG INTERACTIONS:
        \(gdiResults.isEmpty ? "None detected" : gdiResults.joined(separator: "\n"))
        
        RISK LEVEL: \(riskLevel.rawValue.uppercased())
        
        Please provide:
        1. A concise 2-3 sentence summary for the patient
        2. A detailed clinical explanation (5-7 sentences)
        3. Exactly 3 specific, actionable recommendations
        
        Format your response as:
        SUMMARY: [your summary]
        DETAILED: [your detailed explanation]
        RECOMMENDATIONS:
        - [recommendation 1]
        - [recommendation 2]
        - [recommendation 3]
        """
        
        // Call Gemini API
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(geminiAPIKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "maxOutputTokens": 1024
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnalysisError.invalidResponse(statusCode: -1, message: "Missing HTTP response")
        }
        
        if httpResponse.statusCode != 200 {
            let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 response>"
            let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
            let preview = trimmed.isEmpty ? "Empty response body" : String(trimmed.prefix(300))
            throw AnalysisError.invalidResponse(statusCode: httpResponse.statusCode, message: preview)
        }
        
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        let text = parts?.first?["text"] as? String ?? ""
        
        // Parse formatted response
        return parseGeminiResponse(text)
    }
    
    private func parseGeminiResponse(_ text: String) -> (summary: String, detailed: String, recommendations: [String]) {
        var summary = ""
        var detailed = ""
        var recommendations: [String] = []
        
        let lines = text.components(separatedBy: .newlines)
        var currentSection = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("SUMMARY:") {
                currentSection = "summary"
                summary = trimmed.replacingOccurrences(of: "SUMMARY:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("DETAILED:") {
                currentSection = "detailed"
                detailed = trimmed.replacingOccurrences(of: "DETAILED:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("RECOMMENDATIONS:") {
                currentSection = "recommendations"
            } else if trimmed.hasPrefix("-") && currentSection == "recommendations" {
                recommendations.append(trimmed.replacingOccurrences(of: "- ", with: ""))
            } else if !trimmed.isEmpty {
                if currentSection == "summary" {
                    summary += " " + trimmed
                } else if currentSection == "detailed" {
                    detailed += " " + trimmed
                }
            }
        }
        
        // Fallback if parsing fails
        if summary.isEmpty {
            summary = "Analysis complete. Risk level: \(text.contains("high") ? "High" : text.contains("moderate") ? "Moderate" : "Low")"
        }
        if detailed.isEmpty {
            detailed = text
        }
        if recommendations.isEmpty {
            recommendations = ["Consult your healthcare provider", "Monitor for side effects", "Take medications as prescribed"]
        }
        
        return (summary, detailed, recommendations)
    }
}
