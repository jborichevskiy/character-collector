import SwiftUI
import Photos

/// Sheet showing OCR analysis results
struct AnalysisSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: CameraViewModel
    let savedCharacters: Set<String>
    let onSave: (AnalyzedCharacter) -> Void
    let onSaveAll: () -> Void
    let onSaveComponent: (ComponentInfo) -> Void

    // Track which characters are expanded to show components
    @State private var expandedCharacters: Set<String> = []
    // Track saved components (by character string)
    @State private var savedComponents: Set<String> = []
    // Track which library characters have had their definitions revealed (for recall practice)
    @State private var revealedCharacters: Set<String> = []
    // Characters that were in library BEFORE this scan (captured on appear, so saving doesn't trigger spoiler)
    @State private var initialLibraryCharacters: Set<String>?
    // Save to Photos state
    @State private var savedToPhotos = false
    @State private var isSavingToPhotos = false
    @State private var showingErrorDetails = false
    // Full-screen image viewer
    @State private var showingFullScreenImage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Captured image preview (tap for full screen)
                    if let image = viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingFullScreenImage = true
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption)
                                    .padding(6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .padding(8)
                            }
                    }

                    // Loading state with detailed progress
                    if viewModel.isAnalyzing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(viewModel.analysisStatus.message)
                                .font(.subheadline)
                                .foregroundStyle(Color.theme.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    } else if viewModel.showError {
                        // Error state with retry option
                        errorView
                    } else {
                        // Word groupings (multi-character compounds only)
                        if viewModel.detectedWords.contains(where: { $0.word.count > 1 }) {
                            wordsSection
                        }

                        // Character breakdown
                        if !viewModel.analyzedCharacters.isEmpty {
                            charactersSection
                        }

                        // Action buttons
                        actionButtons
                    }
                }
                .padding()
            }
            .background(Color.theme.background)
            .navigationTitle("Character Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.reset()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        saveToPhotos()
                    } label: {
                        if isSavingToPhotos {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: savedToPhotos ? "checkmark.circle.fill" : "square.and.arrow.up")
                        }
                    }
                    .disabled(savedToPhotos || isSavingToPhotos || viewModel.capturedImage == nil)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            // Capture which characters were already in library before this session
            if initialLibraryCharacters == nil {
                initialLibraryCharacters = savedCharacters
            }
        }
        .sheet(isPresented: $showingErrorDetails) {
            errorDetailsSheet
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            ZoomableImageViewer(image: viewModel.capturedImage) {
                showingFullScreenImage = false
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(Color.theme.danger)

            Text("Analysis Failed")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.text)

            Text(viewModel.errorMessage ?? "An unknown error occurred")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.retryAnalysis()
                    }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showingErrorDetails = true
                } label: {
                    Label("Details", systemImage: "info.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.surface)
                        .foregroundStyle(Color.theme.text)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
    }

    private var errorDetailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Error Message")
                        .font(.headline)
                        .foregroundStyle(Color.theme.text)

                    Text(viewModel.errorMessage ?? "No message")
                        .font(.body)
                        .foregroundStyle(Color.theme.textMuted)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("Full Error Details")
                        .font(.headline)
                        .foregroundStyle(Color.theme.text)

                    Text(viewModel.errorDetails ?? "No details available")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.theme.textMuted)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Copy button
                    Button {
                        let text = """
                        Error: \(viewModel.errorMessage ?? "Unknown")

                        Details:
                        \(viewModel.errorDetails ?? "None")
                        """
                        UIPasteboard.general.string = text
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.theme.surface)
                            .foregroundStyle(Color.theme.text)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .background(Color.theme.background)
            .navigationTitle("Error Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showingErrorDetails = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var wordsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Words")
                .font(.headline)
                .foregroundStyle(Color.theme.text)

            ForEach(viewModel.detectedWords.filter { $0.word.count > 1 }) { word in
                HStack(spacing: 12) {
                    Text(word.word)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Color.theme.text)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(word.pinyin)
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.accent)
                        Text(word.meaning)
                            .font(.caption)
                            .foregroundStyle(Color.theme.textMuted)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var charactersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Characters (\(viewModel.analyzedCharacters.count))")
                .font(.headline)
                .foregroundStyle(Color.theme.text)

            ForEach(viewModel.analyzedCharacters) { analyzed in
                VStack(spacing: 0) {
                    // Main character row
                    CharacterResultCard(
                        analyzed: analyzed,
                        isSaved: savedCharacters.contains(analyzed.character) || analyzed.isSaved,
                        isInLibrary: initialLibraryCharacters?.contains(analyzed.character) ?? false,
                        isRevealed: revealedCharacters.contains(analyzed.character),
                        componentCount: analyzed.info.components.count,
                        isExpanded: expandedCharacters.contains(analyzed.character),
                        onSave: { onSave(analyzed) },
                        onToggleExpand: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedCharacters.contains(analyzed.character) {
                                    expandedCharacters.remove(analyzed.character)
                                } else {
                                    expandedCharacters.insert(analyzed.character)
                                }
                            }
                        },
                        onReveal: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                _ = revealedCharacters.insert(analyzed.character)
                            }
                        }
                    )

                    // Expandable components
                    if expandedCharacters.contains(analyzed.character) && !analyzed.info.components.isEmpty {
                        VStack(spacing: 4) {
                            ForEach(analyzed.info.components) { component in
                                ComponentRow(
                                    component: component,
                                    isSaved: savedCharacters.contains(component.character) || savedComponents.contains(component.character),
                                    onSave: {
                                        savedComponents.insert(component.character)
                                        onSaveComponent(component)
                                    }
                                )
                            }
                        }
                        .padding(.leading, 40)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Save all button
            Button {
                onSaveAll()
            } label: {
                Label("Save All to Library", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Take another
            Button {
                viewModel.reset()
                dismiss()
            } label: {
                Label("Take Another", systemImage: "camera")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.theme.surface)
                    .foregroundStyle(Color.theme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.top, 8)
    }

    private func saveToPhotos() {
        guard let image = viewModel.capturedImage else { return }
        isSavingToPhotos = true

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    savedToPhotos = true
                }
                isSavingToPhotos = false
            }
        }
    }
}

struct CharacterResultCard: View {
    let analyzed: AnalyzedCharacter
    let isSaved: Bool
    let isInLibrary: Bool  // Was already in library before this scan
    let isRevealed: Bool   // Has user tapped to reveal the definition
    let componentCount: Int
    let isExpanded: Bool
    let onSave: () -> Void
    let onToggleExpand: () -> Void
    let onReveal: () -> Void

    // Should show spoiler blur for library characters that haven't been revealed
    private var showSpoiler: Bool {
        isInLibrary && !isRevealed
    }

    var body: some View {
        HStack(spacing: 16) {
            // Expand indicator (if has components)
            if componentCount > 0 {
                Button {
                    onToggleExpand()
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textMuted)
                        .frame(width: 16)
                }
            } else {
                Color.clear.frame(width: 16)
            }

            // Character
            Text(analyzed.character)
                .font(.system(size: 40))
                .foregroundStyle(Color.theme.text)
                .frame(width: 50)

            // Info (with spoiler blur for library characters)
            ZStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if !analyzed.info.pinyin.isEmpty {
                            Text(analyzed.info.pinyin)
                                .font(.body)
                                .foregroundStyle(Color.theme.accent)
                        }
                        if componentCount > 0 {
                            Text("(\(componentCount))")
                                .font(.caption)
                                .foregroundStyle(Color.theme.textMuted)
                        }
                    }

                    Text(analyzed.info.meaning)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textMuted)
                        .lineLimit(2)
                }
                .blur(radius: showSpoiler ? 6 : 0)
                .animation(.easeOut(duration: 0.2), value: showSpoiler)

                // Tap to reveal overlay
                if showSpoiler {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash")
                            .font(.caption)
                        Text("Tap to reveal")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.theme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.theme.surface.opacity(0.8))
                    .clipShape(Capsule())
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if showSpoiler {
                    onReveal()
                }
            }

            Spacer()

            // Save button
            Button {
                onSave()
            } label: {
                Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .foregroundStyle(isSaved ? Color.theme.success : Color.theme.primary)
            }
            .disabled(isSaved)
        }
        .padding()
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture {
            if showSpoiler {
                onReveal()
            } else if componentCount > 0 {
                onToggleExpand()
            }
        }
    }
}

struct ComponentRow: View {
    let component: ComponentInfo
    let isSaved: Bool
    let onSave: () -> Void

    private var typeLabel: String {
        switch component.type {
        case .semantic: return "meaning"
        case .phonetic: return "sound"
        case .both: return "both"
        }
    }

    private var typeColor: Color {
        switch component.type {
        case .semantic: return Color.theme.success
        case .phonetic: return Color.theme.accent
        case .both: return Color.theme.primary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(component.character)
                .font(.system(size: 28))
                .foregroundStyle(Color.theme.text)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(component.pinyin)
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.accent)

                    Text(typeLabel)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(typeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                Text(component.meaning)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                onSave()
            } label: {
                Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle")
                    .font(.body)
                    .foregroundStyle(isSaved ? Color.theme.success : Color.theme.primary)
            }
            .disabled(isSaved)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Full-screen zoomable image viewer
struct ZoomableImageViewer: View {
    let image: UIImage?
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 5)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1 {
                                        withAnimation(.spring()) {
                                            scale = 1
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.5
                                }
                            }
                        }
                }

                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }

                // Zoom hint (only shows at 1x)
                if scale == 1.0 {
                    VStack {
                        Spacer()
                        Text("Pinch to zoom • Double-tap to zoom in")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}
