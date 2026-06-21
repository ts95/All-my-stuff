import SwiftUI
import PhotosUI
import Dependencies

struct ItemFormSheet: View {
    @Bindable var item: Item
    @Dependency(\.itemStore) private var itemStore
    @Environment(\.dismiss) private var dismiss

    var isCreateMode: Bool
    let onCancel: () -> Void
    let onDone: () -> Void

    @State private var photoSelection: PhotosPickerItem?
    @State private var isSaving = false
    @State private var isProcessingPhoto = false
    @State private var previewImage: Image?
    @State private var purchasePriceText = ""
    @State private var estimatedValueText = ""
    @State private var saveError: String?

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )
    }

    private var isValid: Bool {
        !item.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var formattedPurchasePriceText: String {
        item.purchasePrice
            .map { String(format: "%.2f", $0) } ?? ""
    }

    private var formattedEstimatedValueText: String {
        item.estimatedValue
            .map { String(format: "%.2f", $0) } ?? ""
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
                statusSection
            }
            .navigationTitle(isCreateMode ? "New Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { @MainActor in
                            isSaving = true
                            do {
                                if isCreateMode {
                                    try itemStore.insert(item)
                                }
                                try itemStore.save(item)
                                onDone()
                                dismiss()
                            } catch {
                                saveError = error.localizedDescription
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
            .alert("Save Error", isPresented: saveErrorBinding) {
                Button("OK") {}
            } message: {
                if let error = saveError {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        Section("Photo") {
            ProcessingOverlay(isProcessing: isProcessingPhoto) {
                if let image = previewImage ?? ImageHelper.imageDataToImage(item.photo) {
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
                        item.photo = ImageHelper.resizeImageData(data)
                        previewImage = ImageHelper.imageDataToImage(data)
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
            TextField("Item name", text: $item.name)
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
            TextEditor(text: $item.notes)
            .frame(minHeight: 80)
        }
    }

    // MARK: - Prices Section

    private var pricesSection: some View {
        Section("Prices") {
            HStack {
                Text("Purchase Price")
                Spacer()
                TextField("0.00", text: $purchasePriceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .onSubmit {
                        commitPurchasePrice()
                    }
            }

            HStack {
                Text("Estimated Value")
                Spacer()
                TextField("0.00", text: $estimatedValueText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .onSubmit {
                        commitEstimatedValue()
                    }
            }
        }
        .task {
            purchasePriceText = formattedPurchasePriceText
            estimatedValueText = formattedEstimatedValueText
        }
        .onDisappear {
            commitPurchasePrice()
            commitEstimatedValue()
        }
    }

    private func commitPurchasePrice() {
        if let value = Double(purchasePriceText), value > 0 {
            item.purchasePrice = value
        } else {
            item.purchasePrice = nil
            purchasePriceText = ""
        }
    }

    private func commitEstimatedValue() {
        if let value = Double(estimatedValueText), value > 0 {
            item.estimatedValue = value
        } else {
            item.estimatedValue = nil
            estimatedValueText = ""
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

    // MARK: - Status Section

    private var statusBinding: Binding<ItemStatus> {
        Binding(
            get: { ItemStatus(rawValue: item.status) ?? .undecided },
            set: { item.status = $0.rawValue }
        )
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: statusBinding) {
                ForEach(ItemStatus.allCases) { status in
                    Text(status.label).tag(status)
                }
            }
        }
    }
}

#Preview {
    let store = ItemStore.preview()
    let item = store.items.first ?? Item(name: "Tablet", datePurchased: Date())

    return ItemFormSheet(
        item: item,
        isCreateMode: false,
        onCancel: {},
        onDone: {}
    )
}