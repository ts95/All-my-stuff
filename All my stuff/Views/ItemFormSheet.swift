import SwiftUI
import SwiftData
import PhotosUI

struct ItemFormSheet: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var isCreateMode: Bool
    let onCancel: () -> Void
    let onDone: () -> Void

    @State private var photoSelection: PhotosPickerItem?
    @State private var isSaving = false
    @State private var isProcessingPhoto = false
    @State private var previewImage: Image?

    private var isValid: Bool {
        !item.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                nameSection
                notesSection
                ItemCategoryPickerView(item: item)
                ItemLocationPickerView(item: item)
                pricesSection
                dateSection
            }
            .navigationTitle(isCreateMode ? "New Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if isCreateMode {
                            modelContext.delete(item)
                        }
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { @MainActor in
                            isSaving = true
                            do {
                                try modelContext.save()
                                onDone()
                                dismiss()
                            } catch {
                                // Save failed - stay on sheet to allow retry
                            }
                            isSaving = false
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Done")
                        }
                    }
                    .disabled(isCreateMode && !isValid || isSaving)
                }
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        Section("Photo") {
            ProcessingOverlay(isProcessing: isProcessingPhoto) {
                if let image = previewImage ?? AssetStorage.imageDataToImage(item.photo) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                }
            }

            PhotosPicker(
                selection: $photoSelection,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "camera")
                    Text("Take Photo or Choose from Library")
                }
            }
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

            if item.photo != nil {
                Button(role: .destructive) {
                    item.photo = nil
                    previewImage = nil
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        Section("Name") {
            TextField("Item name", text: Binding(
                get: { item.name },
                set: { item.name = $0 }
            ))
            .autocapitalization(.sentences)

            if isCreateMode && !isValid {
                Text("A name is required")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: Binding(
                get: { item.notes },
                set: { item.notes = $0 }
            ))
            .frame(minHeight: 80)
        }
    }

    // MARK: - Prices Section

    private var pricesSection: some View {
        Section("Prices") {
            HStack {
                Text("Purchase Price")
                Spacer()
                TextField("0.00", value: Binding(
                    get: { item.purchasePrice?.numericValue ?? 0 },
                    set: { newValue in
                        item.purchasePrice = newValue > 0 ? .confirmed(newValue) : nil
                    }
                ), format: .number.precision(.fractionLength(2)))
                .multilineTextAlignment(.trailing)
            }

            HStack {
                Text("Estimated Value")
                Spacer()
                TextField("0.00", value: Binding(
                    get: { item.estimatedValue?.numericValue ?? 0 },
                    set: { newValue in
                        item.estimatedValue = newValue > 0 ? .assumed(newValue) : nil
                    }
                ), format: .number.precision(.fractionLength(2)))
                .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        Section("Date Purchased") {
            DatePicker("Purchased", selection: Binding(
                get: { item.datePurchased ?? Date.distantPast },
                set: { item.datePurchased = $0 }
            ), displayedComponents: .date)
        }
    }
}
