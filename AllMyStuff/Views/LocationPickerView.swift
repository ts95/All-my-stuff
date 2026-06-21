import SwiftUI
import Dependencies

struct ItemLocationPickerView: View {
    @Bindable var item: Item
    @Dependency(\.locationStore) private var locationStore

    @State private var newLocationText = ""

    var availableLocations: [ItemLocation] {
        locationStore.items.filter { !locations.contains($0) }
    }

    var locations: [ItemLocation] {
        get { item.locations ?? [] }
        set { item.locations = newValue }
    }

    var body: some View {
        Section("Locations") {
            if locations.isEmpty && locationStore.items.isEmpty && newLocationText.isEmpty {
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

            if !availableLocations.isEmpty {
                ForEach(availableLocations, id: \.id) { loc in
                    HStack {
                        Button {
                            var current = item.locations ?? []
                            current.append(loc)
                            item.locations = current
                        } label: {
                            Label(loc.name, systemImage: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(role: .destructive) {
                            do {
                                try locationStore.delete(loc)
                            } catch {
                                print("Failed to delete location: \(error)")
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                TextField("New location", text: $newLocationText)
                    .submitLabel(.done)
                    .textFieldStyle(.roundedBorder)

                Button {
                    addNewLocation()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .disabled(newLocationText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .onSubmit {
                addNewLocation()
            }
        }
        .task {
            do {
                try locationStore.fetchAll()
            } catch {
                print("Failed to fetch locations: \(error)")
            }
        }
    }

    private func addNewLocation() {
        let name = newLocationText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let newLoc = ItemLocation(name: name)
        do {
            try locationStore.insert(newLoc)
            try locationStore.save(newLoc)
        } catch {
            print("Failed to create location: \(error)")
        }

        var current = item.locations ?? []
        current.append(newLoc)
        item.locations = current
        newLocationText = ""
    }
}
