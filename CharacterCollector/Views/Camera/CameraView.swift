import SwiftUI
import SwiftData
import PhotosUI

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedCharacters: [CharacterCard]
    @Query(sort: \CapturedPhoto.capturedAt, order: .reverse)
    private var capturedPhotos: [CapturedPhoto]
    @State private var viewModel = CameraViewModel()

    // Photo picker
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isLoadingPhoto = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Photo history grid
                    PhotoHistoryGrid(
                        photos: Array(capturedPhotos.prefix(20)),
                        onPhotoTap: { photo in
                            Task {
                                await viewModel.loadFromHistory(photo)
                            }
                        }
                    )
                    .padding(.top, 8)

                    Spacer()

                    // Action buttons
                    HStack(spacing: 20) {
                        // Gallery picker
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                Text("Gallery")
                                    .font(.caption)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color.theme.surface)
                            .foregroundStyle(Color.theme.text)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Camera button
                        Button {
                            showCamera = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .frame(width: 80, height: 80)
                                .background(Color.theme.primary)
                                .foregroundStyle(.white)
                                .clipShape(Circle())
                        }

                        // Placeholder for symmetry
                        Color.clear
                            .frame(width: 80, height: 80)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Capture")
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard newItem != nil else { return }
                isLoadingPhoto = true
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        isLoadingPhoto = false
                        await viewModel.processImage(image)
                        // Auto-save photo to history
                        await viewModel.savePhotoToHistory(modelContext: modelContext)
                    } else {
                        isLoadingPhoto = false
                    }
                    selectedPhotoItem = nil
                }
            }
            .overlay {
                if isLoadingPhoto {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Loading photo...")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCapture { image in
                    Task {
                        await viewModel.processImage(image)
                        // Auto-save photo to history
                        await viewModel.savePhotoToHistory(modelContext: modelContext)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAnalysisSheet) {
                AnalysisSheet(
                    viewModel: viewModel,
                    savedCharacters: Set(savedCharacters.map { $0.character }),
                    onSave: saveCharacter,
                    onSaveAll: saveAllCharacters,
                    onSaveComponent: saveComponent
                )
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    private func saveCharacter(_ analyzed: AnalyzedCharacter) {
        // Check if already saved
        if let existing = savedCharacters.first(where: { $0.character == analyzed.character }) {
            // Link existing card to current photo
            viewModel.linkCharacterToPhoto(existing)
            viewModel.markAsSaved(analyzed.character)
            return
        }

        let card = CharacterCard.from(
            character: analyzed.character,
            info: analyzed.info,
            context: viewModel.ocrText
        )
        modelContext.insert(card)
        // Link to current photo
        viewModel.linkCharacterToPhoto(card)
        viewModel.markAsSaved(analyzed.character)
    }

    private func saveAllCharacters() {
        let existingChars = Set(savedCharacters.map { $0.character })

        for analyzed in viewModel.analyzedCharacters where !existingChars.contains(analyzed.character) {
            let card = CharacterCard.from(
                character: analyzed.character,
                info: analyzed.info,
                context: viewModel.ocrText
            )
            modelContext.insert(card)
            viewModel.linkCharacterToPhoto(card)
            viewModel.markAsSaved(analyzed.character)
        }
    }

    private func saveComponent(_ component: ComponentInfo) {
        // Check if already saved
        guard !savedCharacters.contains(where: { $0.character == component.character }) else {
            return
        }

        let card = CharacterCard.from(
            component: component,
            context: viewModel.ocrText
        )
        modelContext.insert(card)
        viewModel.linkCharacterToPhoto(card)
    }
}

#Preview {
    CameraView()
        .modelContainer(for: [CharacterCard.self, CapturedPhoto.self], inMemory: true)
}
