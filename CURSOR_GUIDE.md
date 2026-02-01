# 🎯 Cursor Quick Start Guide - MedGuard App

## What is Front-End vs Back-End?

### Front-End (What You're Building)
- **The iOS App** - Everything users see and interact with
- **Written in:** Swift & SwiftUI
- **Runs on:** iPhone
- **Contains:**
  - User interface (buttons, screens, animations)
  - Camera integration (Presage SDK)
  - Local data storage
  - Client-side calculations
  - Direct API calls to Gemini

### Back-End (Optional for Hackathon)
- **Server** - Remote computer that processes data
- **Written in:** Node.js, Python, or any server language
- **Runs on:** Cloud (AWS, Google Cloud, etc.)
- **Would contain:**
  - Drug database
  - User accounts
  - Secure API key storage
  - Heavy computations

### For Your Hackathon: **NO BACKEND NEEDED!** ✅

Everything runs in the iOS app:
- DNA parsing: ✅ iOS app
- Drug interactions: ✅ iOS app (hardcoded database)
- Activity score: ✅ iOS app calculation
- Gemini AI: ✅ iOS app calls API directly
- Vitals monitoring: ✅ iOS app with Presage SDK

## 🚀 Step-by-Step Cursor Workflow

### Step 1: Create Xcode Project (5 minutes)

1. **Open Xcode** (not Cursor yet)
2. File → New → Project
3. Choose **iOS → App**
4. Settings:
   - Product Name: `MedGuard`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Click **Create**

### Step 2: Add Presage SDK (10 minutes)

1. Download the SmartSpectra SDK (from the documentation you provided)
2. In Xcode:
   - File → Add Package Dependencies
   - Click **Add Local**
   - Select the SDK folder
3. Wait for it to index

### Step 3: Open in Cursor (NOW!)

1. **Close Xcode** (important!)
2. **Open Cursor**
3. File → Open Folder
4. Select your `MedGuard` project folder

### Step 4: Create Files with Cursor

#### Vibe Code Prompt #1: ContentView.swift

```
Create a SwiftUI ContentView.swift for an iOS health app called MedGuard.

Requirements:
- Beautiful gradient background (purple to blue)
- 4 workflow cards:
  1. Upload DNA Data (blue, doc icon)
  2. Enter Medications (green, pills icon)
  3. Record Baseline Vitals (pink, heart icon)
  4. Get Analysis (yellow, chart icon)
- Each card shows a title, subtitle, and navigation button
- Track completion state for each step
- Show user stats at bottom if data exists
- Modern, clean design

Use NavigationView and create placeholder views for:
- DNAUploadView
- MedicationInputView  
- VitalsMonitorView
- AnalysisResultsView

Import SmartSpectraSwiftSDK and configure it in init()
```

#### Vibe Code Prompt #2: AppState.swift

```
Create AppState.swift for centralized state management.

Models needed:
1. Medication (id, name, dosage, frequency)
2. VitalsData (heartRate, breathingRate, timestamp, isValid)
3. DNAProfile (cytochromeData dictionary, CYP2D6/2C19/2C9/3A4/1A2 properties)
4. UserProfile (age, sex, weight, smokingStatus, medicalConditions array)
5. RiskLevel enum (safe=green, caution=yellow, danger=red)
6. AnalysisResult (riskLevel, summary, detailedReport, interactions, recommendations)

AppState @Published properties:
- userProfile, dnaProfile, medications array
- baselineVitals, followUpVitals array
- currentAnalysis, analysisHistory
- workflow booleans (dnaDataUploaded, medicationsEntered, etc.)
- isLoading, errorMessage

Methods needed:
- uploadDNAData(fileURL) - parse 23andMe file for CYP genes
- addMedication, removeMedication, updateMedication
- recordBaselineVitals, recordFollowUpVitals
- performAnalysis() - async function that:
  * Calculates activity score from genetics
  * Checks drug-drug interactions
  * Checks gene-drug interactions
  * Calls Gemini API for AI summary
  * Returns AnalysisResult

Include BackendAPIService class with:
- calculateActivityScore based on CYP variants, age, sex, smoking
- checkDrugDrugInteractions with hardcoded known pairs
- checkGeneDrugInteractions matching drugs to genes
- generateGeminiSummary calling Gemini API

Use this Gemini API key: AIzaSyAg24n-YWgkJf8aka251yUPEkKTOLFBdiM
```

#### Vibe Code Prompt #3: VitalsMonitorView.swift

```
Create VitalsMonitorView.swift using SmartSpectraSwiftSDK.

Requirements:
- Purple gradient background
- Show "Baseline Vitals" or "Follow-up Monitoring" based on isBaseline parameter
- Include SmartSpectraView() from SDK
- Display real-time heart rate and breathing rate from sdk.metricsBuffer
- Show processor.statusHint for user guidance
- "Save Vitals" button appears when measurement is complete
- Save to appState.recordBaselineVitals() or recordFollowUpVitals()
- Show alert confirmation when saved
- Auto-dismiss after saving

Style:
- Modern card layout
- Real-time vital readouts with icons
- Color-coded status indicators
- Smooth animations
```

#### Vibe Code Prompt #4: MedicationInputView.swift

```
Create MedicationInputView.swift for medication management.

Features:
- Green gradient background  
- List of added medications with cards showing name, dosage, frequency
- Tap + button to add new medication
- Long press or swipe to edit/delete
- Sheet modal for adding medication with form:
  * Name text field
  * Dosage text field  
  * Frequency picker (Once daily, Twice daily, etc.)
- Empty state with helpful message
- Clean, modern card design
```

#### Vibe Code Prompt #5: DNAUploadView.swift

```
Create DNAUploadView.swift for uploading 23andMe data.

Features:
- Blue gradient background
- Instructions cards numbered 1-3 explaining process
- File picker button to select .txt or .zip file
- Show loading overlay while processing
- Display extracted genetic profile after upload:
  * Show each CYP gene and genotype in monospaced font
  * Upload date
  * Checkmark icon when complete
- Handle errors gracefully with alerts
- "Upload New File" button if already uploaded
```

#### Vibe Code Prompt #6: AnalysisResultsView.swift

```
Create AnalysisResultsView.swift to display analysis results.

Features:
- Purple gradient background
- Before analysis: Show "Ready to Analyze" with "Run Analysis" button
- After analysis:
  * Large traffic light risk indicator (green/yellow/red circle with icon)
  * AI summary card
  * Detailed analysis card  
  * Gene-drug interactions list (if any)
  * Drug-drug interactions list (if any)
  * Numbered recommendations
  * Monitoring recommendation if yellow/red
  * "Share Report with Doctor" button
- Loading overlay while analyzing with "Powered by Gemini AI"
- Modern card layouts with shadows
```

### Step 5: Build with Cursor (The Fun Part!)

1. **Create each file** using the prompts above:
   - Press `Cmd+N` in Cursor
   - Paste the prompt in Cursor chat
   - It will generate the code
   - Copy to a new .swift file in Xcode

2. **Iterate and improve:**
   ```
   "Make the gradient more vibrant"
   "Add smooth animations when cards appear"
   "Make the buttons more rounded and modern"
   "Add haptic feedback when buttons are pressed"
   "Improve error handling for file upload"
   ```

3. **Fix issues:**
   ```
   "I'm getting error: Cannot find 'SmartSpectraView' in scope"
   → Cursor will help you import the SDK correctly
   
   "The gradient isn't showing"
   → Cursor will fix the ignoresSafeArea() issue
   
   "Vitals aren't updating in real-time"  
   → Cursor will add proper @ObservedObject bindings
   ```

### Step 6: Test in Xcode (NOT Cursor)

1. **Close Cursor**
2. **Open Xcode**
3. Connect iPhone via USB
4. Press **Run** (⌘R)
5. Test each feature

### Step 7: Debug with Cursor

When you hit errors:

1. Copy error message from Xcode
2. Open Cursor
3. Paste error and ask:
   ```
   "Fix this error: [paste error]"
   
   "The vitals aren't displaying, here's my code: [paste code]"
   
   "How do I add camera permissions to Info.plist?"
   ```

## 💡 Pro Cursor Tips

### Ask for Complete Features
```
"Add a settings page where users can edit their profile (age, sex, medical conditions)"
```

### Request Design Improvements
```
"Make this look like a premium health app - add shadows, better spacing, modern colors"
```

### Get Help with Integration
```
"How do I integrate the Presage SDK to show vitals in my custom view?"
```

### Debug Specific Issues
```
"The Gemini API call is failing with 400 error, here's my code: [paste]"
```

### Optimize Performance
```
"The app is laggy when processing vitals, how can I optimize this?"
```

## 🎨 Design Enhancements with Cursor

```
"Add subtle animations when cards appear using withAnimation"

"Create a custom loading spinner that matches our purple theme"

"Add confetti animation when analysis shows green (safe)"

"Make the risk level card pulse if it's red"

"Add a dark mode that looks professional"
```

## 🔧 Common Issues & Cursor Solutions

### Issue: "SwiftUI Preview not working"
```
Cursor prompt: "Create a #Preview for this view with sample AppState data"
```

### Issue: "Async/await errors"
```
Cursor prompt: "Convert this to use async/await properly in SwiftUI"
```

### Issue: "State not updating"
```
Cursor prompt: "Fix the @Published properties so SwiftUI reacts to changes"
```

### Issue: "File picker not working"
```
Cursor prompt: "Implement fileImporter that works with security-scoped URLs"
```

## 🚀 Advanced Features to Add

Once basic app works, enhance with Cursor:

```
"Add HealthKit integration to pull historical heart rate data"

"Create a chart showing vitals over time using Swift Charts"

"Add push notifications to remind users to take measurements"

"Implement Face ID authentication to protect health data"

"Create a widget showing latest vitals on home screen"

"Add export to PDF functionality for reports"

"Implement local database using CoreData to save history"
```

## ✅ Final Checklist

- [ ] All 6 .swift files created
- [ ] Presage SDK integrated
- [ ] API keys added
- [ ] Camera permission in Info.plist
- [ ] Builds without errors in Xcode
- [ ] Tested on physical iPhone
- [ ] UI looks polished
- [ ] All features work end-to-end

## 🎬 Demo Video Script

Use Cursor to help:
```
"Write a 60-second demo script for a hackathon pitch video explaining MedGuard"
```

## 🏆 Hackathon Submission

Cursor can help with:
```
"Write a compelling DevPost description for this hackathon project"

"Create a one-page technical architecture diagram explanation"

"Write bullet points of challenges we overcame"
```

---

**Remember:** Cursor is your coding partner! Treat it like a senior developer you're pair programming with. Ask questions, request explanations, and iterate until it's perfect.

**You CAN do this!** 🚀
