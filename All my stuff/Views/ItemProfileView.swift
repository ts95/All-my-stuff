import SwiftUI
import SwiftData
import PhotosUI

struct ItemProfileView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var photoSelection: PhotosPickerItem?
    @State private var isProcessingPhoto = false
    @State private var previewImage: Image?

    var body: some View {
        Form {
            photoSection
            nameNotesSection
            categoriesSection
            locationsSection
            pricesSection
            datePurchasedSection
            deleteSection
        }
        .navigationTitle(item.name.isEmpty ? "Item" : item.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { onEdit() }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive, action: {
                    modelContext.delete(item)
                    onDelete()
                }) {
                    Text("Delete")
                }
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        Section {
            ProcessingOverlay(isProcessing: isProcessingPhoto) {
                if let image = previewImage ?? AssetStorage.imageDataToImage(item.photo) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No photo")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                }
            }

            PhotosPicker(
                selection: $photoSelection,
                matching: .images
            ) {
                EmptyView()
            }
            .opacity(0)
            .frame(width: 1, height: 1)
            .accessibilityHidden(true)
            .onChange(of: photoSelection) { _, newValue in
                Task {
                    isProcessingPhoto = true
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        item.photo = AssetStorage.resizeImageData(data)
                        previewImage = AssetStorage.imageDataToImage(data)
                    }
                    isProcessingPhoto = false
                }
            }
        }
    }

    // MARK: - Name & Notes Section

    private var nameNotesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.name)
                    .font(.headline)
            }

            if !item.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.notes)
                        .font(.body)
                        .lineLimit(5)
                }
            }
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        Section("Categories") {
            if let categories = item.categories, !categories.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading) {
                    ForEach(categories, id: \.persistentModelID) { cat in
                        Text(cat.name)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                    }
                }
            } else {
                Text("No categories")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    // MARK: - Locations Section

    private var locationsSection: some View {
        Section("Locations") {
            if let locations = item.locations, !locations.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading) {
                    ForEach(locations, id: \.persistentModelID) { loc in
                        Text(loc.name)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1), in: Capsule())
                    }
                }
            } else {
                Text("No locations")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    // MARK: - Prices Section

    private var pricesSection: some View {
        Section("Prices") {
            HStack {
                Text("Purchase Price")
                Spacer()
                Text(item.purchasePrice?.displayValue ?? "Not set")
                    .foregroundStyle(item.purchasePrice != nil ? .primary : .secondary)
            }

            HStack {
                Text("Estimated Value")
                Spacer()
                Text(item.estimatedValue?.displayValue ?? "Not set")
                    .foregroundStyle(item.estimatedValue != nil ? .primary : .secondary)
            }
        }
    }

    // MARK: - Date Purchased Section

    private var datePurchasedSection: some View {
        Group {
            if let date = item.datePurchased {
                Section("Date Purchased") {
                    HStack {
                        Text("Purchased")
                        Spacer()
                        Text(date, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                modelContext.delete(item)
                onDelete()
            } label: {
                Label("Delete Item", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
        }
    }

}
