import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab (existing ContentView)
            NavigationStack {
                ContentView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            .tag(0)
            
            // Progress Tab (measurements)
            NavigationStack {
                ProgressView()
            }
            .tabItem {
                Label("Metrics", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(1)
            
            // Progress Photos Tab (new)
            NavigationStack {
                ProgressPhotosView()
            }
            .tabItem {
                Label("Photos", systemImage: "photo.fill")
            }
            .tag(2)
            
            // Nutrition Tab
            NavigationStack {
                PlaceholderView(title: "Nutrition")
            }
            .tabItem {
                Label("Nutrition", systemImage: "fork.knife")
            }
            .tag(3)
            
            // Workout Tab
            NavigationStack {
                PlaceholderView(title: "Workout")
            }
            .tabItem {
                Label("Workout", systemImage: "dumbbell.fill")
            }
            .tag(4)
        }
        .accentColor(.green)
    }
}

// Placeholder view for tabs that aren't implemented yet
struct PlaceholderView: View {
    let title: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Coming Soon")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding(.top, 5)
            
            Spacer()
        }
        .padding()
        .navigationTitle(title)
    }
}

#Preview {
    MainTabView()
} 