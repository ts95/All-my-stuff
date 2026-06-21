import SwiftUI
import Dependencies

struct ItemLocationPickerView: View {
    @Bindable var item: Item
    @Dependency(\.locationStore) private var locationStore

    var availableLocations: [ItemLocation] {
        locationStore.items.filter { !locations.contains($0) }
    }

    var locations: [ItemLocation] {
        get { item.locations ?? [] }
        set { item.locations = newValue }
    }

    var body: some View {
        Section("Locations") {
            if locations.isEmpty && locationStore.items.isEmpty {
                Text("No locations yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(locations, id: \.id) { loc in
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

            ForEach(availableLocations, id: \.id) { loc in
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
                        do {
                            try locationStore.insert(newLoc)
                            try locationStore.save(newLoc)
                        } catch {
                            print("Failed to create location: \(error)")
                        }
                        var current = item.locations ?? []
                        current.append(newLoc)
                        item.locations = current
                    }
                }
            ))
            .submitLabel(.done)
            .textFieldStyle(.roundedBorder)
        }
        .task {
            do {
                try locationStore.fetchAll()
            } catch {
                print("Failed to fetch locations: \(error)")
            }
        }
    }
}
