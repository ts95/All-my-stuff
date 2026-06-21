import Dependencies
import SwiftData

// MARK: - Shared Container

enum AppContainer {
    static var shared: ModelContainer?
}

// MARK: - ItemStore Dependency

extension ItemStore: DependencyKey {
    static var liveValue: ItemStore {
        .live(context: AppContainer.shared!.mainContext)
    }
    static var previewValue: ItemStore { .preview() }
    static var testValue: ItemStore { .test() }
}

extension DependencyValues {
    var itemStore: ItemStore {
        get { self[ItemStore.self] }
        set { self[ItemStore.self] = newValue }
    }
}

// MARK: - CategoryStore Dependency

extension CategoryStore: DependencyKey {
    static var liveValue: CategoryStore {
        .live(context: AppContainer.shared!.mainContext)
    }
    static var previewValue: CategoryStore { .preview() }
    static var testValue: CategoryStore { .test() }
}

extension DependencyValues {
    var categoryStore: CategoryStore {
        get { self[CategoryStore.self] }
        set { self[CategoryStore.self] = newValue }
    }
}

// MARK: - LocationStore Dependency

extension LocationStore: DependencyKey {
    static var liveValue: LocationStore {
        .live(context: AppContainer.shared!.mainContext)
    }
    static var previewValue: LocationStore { .preview() }
    static var testValue: LocationStore { .test() }
}

extension DependencyValues {
    var locationStore: LocationStore {
        get { self[LocationStore.self] }
        set { self[LocationStore.self] = newValue }
    }
}

// MARK: - Prepare Dependencies

func prepareDependencies(modelContainer: ModelContainer) {
    AppContainer.shared = modelContainer
    prepareDependencies {
        $0.itemStore = .live(context: modelContainer.mainContext)
        $0.categoryStore = .live(context: modelContainer.mainContext)
        $0.locationStore = .live(context: modelContainer.mainContext)
    }
}
