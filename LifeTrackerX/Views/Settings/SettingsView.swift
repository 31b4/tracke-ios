import SwiftUI
import HealthKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthManager = HealthManager()
    @ObservedObject var historyManager: StatsHistoryManager
    @State private var showHealthAccessSheet = false
    
    // Computed property to check if Apple Health is actively connected
    private var isAppleHealthConnected: Bool {
        let weightEntries = historyManager.getEntries(for: .weight, source: .appleHealth)
        let heightEntries = historyManager.getEntries(for: .height, source: .appleHealth)
        let bodyFatEntries = historyManager.getEntries(for: .bodyFat, source: .appleHealth)
        return !weightEntries.isEmpty || !heightEntries.isEmpty || !bodyFatEntries.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Health Data")) {
                    Button(action: {
                        showHealthAccessSheet = true
                    }) {
                        HStack {
                            Image("applehealthdark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("Apple Health")
                                .foregroundColor(.primary)
                            Spacer()
                            if healthManager.isHealthDataAvailable {
                                if healthManager.isAuthorized {
                                    if isAppleHealthConnected {
                                        Text("Connected")
                                            .foregroundColor(.green)
                                    } else {
                                        Text("Disconnected")
                                            .foregroundColor(.orange)
                                    }
                                } else {
                                    Text("Not Authorized")
                                        .foregroundColor(.orange)
                                }
                            } else {
                                Text("Not Available")
                                    .foregroundColor(.gray)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                
                Section(header: Text("Account")) {
                    Button(action: {
                        // Sign out action
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Appearance")) {
                    NavigationLink(destination: Text("Theme Settings")) {
                        Label("Theme", systemImage: "paintbrush.fill")
                    }
                    
                    NavigationLink(destination: Text("Units Settings")) {
                        Label("Units", systemImage: "ruler")
                    }
                }
                
                Section(header: Text("About")) {
                    NavigationLink(destination: Text("Privacy Policy")) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }
                    
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showHealthAccessSheet) {
                HealthAccessView(healthManager: healthManager, historyManager: historyManager)
            }
        }
    }
}

struct HealthAccessView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var healthManager: HealthManager
    @ObservedObject var historyManager: StatsHistoryManager
    @State private var showDebugInfo = false
    @State private var isLoading = false
    @State private var isRefreshing = false
    @State private var showingActionSheet = false
    
    // Computed property to check if there are any Apple Health entries
    private var hasAppleHealthData: Bool {
        let weightEntries = historyManager.getEntries(for: .weight, source: .appleHealth)
        let heightEntries = historyManager.getEntries(for: .height, source: .appleHealth)
        let bodyFatEntries = historyManager.getEntries(for: .bodyFat, source: .appleHealth)
        return !weightEntries.isEmpty || !heightEntries.isEmpty || !bodyFatEntries.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                RefreshControl(isRefreshing: $isRefreshing) {
                    refreshData()
                }
                
                VStack(spacing: 20) {
                    Image("applehealthdark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding(.top, 40)
                    
                    Text("Connect to Apple Health")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("This app needs access to your health data to provide accurate tracking and insights. Your data will be automatically synced with Apple Health.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HealthDataTypeRow(icon: "scalemass.fill", title: "Weight", description: "Track your weight changes over time")
                        HealthDataTypeRow(icon: "ruler.fill", title: "Height", description: "Used for BMI calculations")
                        HealthDataTypeRow(icon: "person.fill", title: "Body Fat Percentage", description: "Monitor body composition")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if healthManager.isAuthorized {
                        if hasAppleHealthData {
                            Button(action: {
                                showingActionSheet = true
                            }) {
                                Text("Disconnect Apple Health")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .confirmationDialog(
                                "Disconnect Apple Health",
                                isPresented: $showingActionSheet,
                                titleVisibility: .visible
                            ) {
                                Button("Disconnect", role: .destructive) {
                                    clearAppleHealthData()
                                }
                            } message: {
                                Text("This will disconnect Apple Health and remove all imported data. You can reconnect later to import data again.")
                            }
                        } else {
                            Button(action: {
                                importHealthData()
                            }) {
                                Text("Connect Apple Health")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        Button(action: {
                            requestAuthorization()
                        }) {
                            Text("Request Health Access")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .padding()
                    }
                    
                    if showDebugInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status: \(healthManager.fetchingStatus)")
                                .bold()
                            
                            Text("Last sync: \(healthManager.lastUpdateTimestamp.formatted())")
                                .font(.caption)
                            
                            Text("Weight entries: \(historyManager.getEntries(for: .weight, source: .appleHealth).count)")
                            ForEach(historyManager.getEntries(for: .weight, source: .appleHealth).prefix(5), id: \.id) { entry in
                                Text("- \(entry.date.formatted()): \(String(format: "%.1f", entry.value)) kg")
                                    .font(.caption)
                            }
                            
                            Text("Height entries: \(historyManager.getEntries(for: .height, source: .appleHealth).count)")
                            ForEach(historyManager.getEntries(for: .height, source: .appleHealth).prefix(5), id: \.id) { entry in
                                Text("- \(entry.date.formatted()): \(String(format: "%.1f", entry.value)) cm")
                                    .font(.caption)
                            }
                            
                            Text("Body Fat entries: \(historyManager.getEntries(for: .bodyFat, source: .appleHealth).count)")
                            ForEach(historyManager.getEntries(for: .bodyFat, source: .appleHealth).prefix(5), id: \.id) { entry in
                                Text("- \(entry.date.formatted()): \(String(format: "%.1f", entry.value))%")
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func requestAuthorization() {
        healthManager.requestHealthAuthorization()
        // After authorization, automatically import data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            importHealthData()
        }
    }
    
    private func importHealthData() {
        isLoading = true
        healthManager.importAllHealthData(historyManager: historyManager) { success in
            isLoading = false
            showDebugInfo = true
        }
    }
    
    private func refreshData() {
        // Only refresh if we have Apple Health data connected
        if hasAppleHealthData {
            isRefreshing = true
            healthManager.importAllHealthData(historyManager: historyManager) { success in
                isRefreshing = false
                showDebugInfo = true
            }
        } else {
            isRefreshing = false
        }
    }
    
    private func clearAppleHealthData() {
        isLoading = true
        
        // Only remove entries that were imported from Apple Health
        historyManager.clearEntries(from: .appleHealth)
        
        // Show the debug info and stop loading
        showDebugInfo = true
        isLoading = false
    }
}

// Custom RefreshControl for pull-to-refresh functionality
struct RefreshControl: View {
    @Binding var isRefreshing: Bool
    let action: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let threshold: CGFloat = -50
            
            VStack {
                if offset < threshold {
                    Spacer()
                        .onAppear {
                            if !isRefreshing {
                                isRefreshing = true
                                action()
                            }
                        }
                }
                
                HStack {
                    Spacer()
                    if isRefreshing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 50)
    }
}

struct HealthDataTypeRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}
