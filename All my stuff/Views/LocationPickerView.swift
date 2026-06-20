import SwiftUI
import SwiftData

struct ItemLocationPickerView: View {
    @Bindable var item: Item
    @Query var allLocations: [ItemLocation]
    @Environment(\.modelContext) private var modelContext

    var availableLocations: [ItemLocation] {
        allLocations.filter { !item.locations.contains($0) }
    }

    var body: some View {
        Section("Locations") {
            if item.locations.isEmpty && allLocations.isEmpty {
                Text("No locations yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(item.locations, id: \.persistentModelID) { loc in
                HStack {
                    Text(loc.name)
                    Spacer()
                    Button(role: .destructive) {
                        item.locations.removeAll { $0 == loc }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            ForEach(availableLocations, id: \.persistentModelID) { loc in
                Button("+ \(loc.name)") {
                    item.locations.append(loc)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }

            TextField("New location", text: Binding(
                get: { "" },
                set: { newValue in
                    if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                        let newLoc = ItemLocation(name: newValue.trimmingCharacters(in: .whitespaces))
                        modelContext.insert(newLoc)
                        item.locations.append(newLoc)
                    }
                }
            ))
            .submitLabel(.done)
            .textFieldStyle(.roundedBorder)
        }
    }
}
