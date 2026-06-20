import SwiftUI
import SwiftData
import PhotosUI

struct ItemDetailView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var photoSelection: PhotosPickerItem?
    @State private var previewImage: Image?

    var body: some View {
        Form {
            Section("Photo") {
                PhotosPicker(selection: $photoSelection, matching: .images) {
                    if let previewImage {
                        previewImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Tap to add a photo")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                    }
                }
                .onChange(of: photoSelection) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            item.photo = AssetStorage.resizeImageData(data)
                            previewImage = AssetStorage.imageDataToImage(data)
                        }
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

            Section("Name") {
                TextField("Item name", text: $item.name)
                    .autocapitalization(.sentences)
            }

            Section("Notes") {
                TextEditor(text: $item.notes)
                    .frame(minHeight: 80)
            }

            ItemCategoryPickerView(item: item)

            ItemLocationPickerView(item: item)

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

            Section("Date Purchased") {
                DatePicker("Purchased", selection: Binding(
                    get: { item.datePurchased ?? Date.distantPast },
                    set: { item.datePurchased = $0 }
                ), displayedComponents: .date)
            }

            Button(role: .destructive) {
                modelContext.delete(item)
                dismiss()
            } label: {
                Label("Delete Item", systemImage: "trash")
            }
        }
        .navigationTitle("Edit Item")
    }
}
