import SwiftUI

struct ProgressPhotosView: View {
    @StateObject private var photoManager = ProgressPhotoManager.shared
    @StateObject private var historyManager = StatsHistoryManager.shared
    @State private var showingAddPhotoSheet = false
    @State private var selectedCategory: PhotoCategory?
    @State private var selectedPhoto: ProgressPhoto?
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 12) {
                    CategoryScrollView(selectedCategory: $selectedCategory)
                    
                    // Before/After comparison cards
                    VStack(spacing: 10) {
                        if let category = selectedCategory {
                            CategoryComparisonView(
                                category: category,
                                photoManager: photoManager,
                                historyManager: historyManager
                            )
                        } else {
                            CategoryGrid(
                                photoManager: photoManager,
                                selectedCategory: $selectedCategory,
                                showingAddPhotoSheet: $showingAddPhotoSheet
                            )
                        }
                    }
                    
                    // Photo history if category is selected
                    if let category = selectedCategory {
                        PhotoHistorySection(
                            category: category,
                            photoManager: photoManager,
                            historyManager: historyManager,
                            selectedPhoto: $selectedPhoto
                        )
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Progress Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if selectedCategory != nil {
                    Button(action: {
                        withAnimation {
                            selectedCategory = nil
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddPhotoSheet = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingAddPhotoSheet) {
            AddPhotoView(
                photoManager: photoManager,
                historyManager: historyManager,
                category: selectedCategory
            )
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(
                photo: photo,
                photoManager: photoManager,
                historyManager: historyManager
            )
        }
    }
}

// MARK: - Category Scroll View
struct CategoryScrollView: View {
    @Binding var selectedCategory: PhotoCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PhotoCategory.allCases) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }
}

// MARK: - Category Comparison View
struct CategoryComparisonView: View {
    let category: PhotoCategory
    let photoManager: ProgressPhotoManager
    let historyManager: StatsHistoryManager
    
    var body: some View {
        let photos = photoManager.getPhotos(for: category)
        
        if photos.count >= 1 {
            ComparisonCard(
                photoManager: photoManager,
                category: category,
                historyManager: historyManager
            )
        } else {
            EmptyStateView(category: category)
                .padding(.horizontal, 4)
        }
    }
}

// MARK: - Category Grid
struct CategoryGrid: View {
    let photoManager: ProgressPhotoManager
    @Binding var selectedCategory: PhotoCategory?
    @Binding var showingAddPhotoSheet: Bool
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            let latestByCategory = photoManager.getLatestPhotosByCategory()
            
            ForEach(PhotoCategory.allCases) { category in
                if let photo = latestByCategory[category] {
                    CategoryPhotoCard(
                        category: category,
                        photo: photo,
                        action: {
                            selectedCategory = category
                        }
                    )
                } else {
                    CategoryEmptyCard(
                        category: category,
                        action: {
                            selectedCategory = category
                            showingAddPhotoSheet = true
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Photo History Section
struct PhotoHistorySection: View {
    let category: PhotoCategory
    let photoManager: ProgressPhotoManager
    let historyManager: StatsHistoryManager
    @Binding var selectedPhoto: ProgressPhoto?
    
    var body: some View {
        VStack {
            Spacer(minLength: 25)
            
            // Section header
            HStack {
                Text("Photo History")
                    .font(.title3)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 5) {
                    Image(systemName: "photo.stack.fill")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("\(photoManager.getPhotos(for: category).count) photos")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            let groupedPhotos = photoManager.getPhotosByDate(category: category)
            
            if groupedPhotos.isEmpty {
                EmptyStateView(category: category)
                    .padding(.horizontal, 4)
            } else {
                // Group by date
                VStack(spacing: 16) {
                    ForEach(groupedPhotos.keys.sorted(by: >), id: \.self) { date in
                        if let photos = groupedPhotos[date] {
                            HistoryDateGroupHeader(date: date)
                                .padding(.horizontal)
                            
                            // Photos grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(photos) { photo in
                                    HistoryPhotoThumbnail(
                                        photo: photo,
                                        historyManager: historyManager
                                    ) {
                                        selectedPhoto = photo
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

struct CategoryButton: View {
    let category: PhotoCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color(red: 0.2, green: 0.2, blue: 0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                Text(category.name)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .frame(width: 55)
    }
}

struct EmptyStateView: View {
    let category: PhotoCategory
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No \(category.name) Photos")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Take your first photo")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .font(.body)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
    }
}

struct CategoryPhotoCard: View {
    let category: PhotoCategory
    let photo: ProgressPhoto
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                if let uiImage = photo.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: category.iconName)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                        
                        Text(category.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if photo.categories.count > 1 {
                            Text("+\(photo.categories.count - 1)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(4)
                        }
                    }
                    
                    // Additional categories list
                    if photo.categories.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(photo.categories.filter { $0 != category }, id: \.self) { cat in
                                    HStack(spacing: 2) {
                                        Image(systemName: cat.iconName)
                                            .font(.system(size: 10))
                                            .foregroundColor(.white)
                                        
                                        Text(cat.name)
                                            .font(.system(size: 10))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.bottom, 2)
                    }
                    
                    Text(formatDate(photo.date))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.3)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
            .cornerRadius(12)
            .frame(height: 150)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct CategoryEmptyCard: View {
    let category: PhotoCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                
                Text(category.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text("Add")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack {
        ProgressPhotosView()
    }
} 