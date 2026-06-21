import SwiftUI

/// A generic overlay that dims content and shows a progress indicator
/// while an asynchronous operation (e.g., image resizing) is in progress.
struct ProcessingOverlay<Content: View>: View {
    let isProcessing: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            content()
            if isProcessing {
                Color.black.opacity(0.3)
                    .overlay { ProgressView() }
            }
        }
    }
}
