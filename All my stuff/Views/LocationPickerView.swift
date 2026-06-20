import SwiftUI
import SwiftData

struct ItemLocationPickerView: View {
    @Bindable var item: Item
    @Query var allLocations: [ItemLocation]
    @Environment(\.modelContext) private var modelContext

    var availableLocations: [ItemLocation] {
        allLocations.filter { !locations.contains($0) }
    }

    var locations: [ItemLocation] {
        get { item.locations ?? [] }
        set { item.locations = newValue }
    }

    var body: some View {
        Section("Locations") {
            if locations.isEmpty && allLocations.isEmpty {
                Text("No locations yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(locations, id: \.persistentModelID) { loc in
                HStack {
                    Text(loc.name)
                    Spacer()
                    Button(role: .destructive) {
                        item.locations = (item.locations ?? []).filter { $0 != loc }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            ForEach(availableLocations, id: \.persistentModelID) { loc in
                Button("+ \(loc.name)") {
                    var current = item.locations ?? []
                    current.append(loc)
                    item.locations = current
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
                        var current = item.locations ?? []
                        current.append(newLoc)
                        item.locations = current
                    }
                }
            ))
            .submitLabel(.done)
            .textFieldStyle(.roundedBorder)
        }
    }
}
