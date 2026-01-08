import SwiftUI
import SwiftData
import AVFoundation

/// Analyzed character with lookup info
struct AnalyzedCharacter: Identifiable {
    let id = UUID()
    let character: String
    let info: CharacterInfo
    var isSaved: Bool = false
}

/// Detailed analysis progress states
enum AnalysisStatus: Equatable {
    case idle
    case uploading
    case recognizingText
    case lookingUpCharacters
    case detectingWords
    case complete
    case error(String)

    var message: String {
        switch self {
        case .idle: return ""
        case .uploading: return "Uploading image to Claude..."
        case .recognizingText: return "Recognizing Chinese text..."
        case .lookingUpCharacters: return "Looking up character definitions..."
        case .detectingWords: return "Detecting word groupings..."
        case .complete: return "Analysis complete"
        case .error(let msg): return msg
        }
    }
}

/// ViewModel for camera capture and OCR analysis
@Observable
final class CameraViewModel {
    // Capture state
    var capturedImage: UIImage?
    var isAnalyzing = false
    var showAnalysisSheet = false

    // OCR results
    var ocrText = ""
    var detectedWords: [WordInfo] = []
    var analyzedCharacters: [AnalyzedCharacter] = []
    var detectedPhrases: [(phrase: String, info: PhraseInfo)] = []

    // Photo history
    var currentPhoto: CapturedPhoto?
    var isLoadingFromHistory = false

    // Analysis progress
    var analysisStatus: AnalysisStatus = .idle

    // Error handling
    var errorMessage: String?
    var errorDetails: String?  // Full error response for debugging
    var showError = false

    private let ocrService = OCRService()
    private let lookupService = CharacterLookupService()

    /// Process a captured image with OCR
    func processImage(_ image: UIImage) async {
        capturedImage = image
        isAnalyzing = true
        showAnalysisSheet = true
        errorMessage = nil
        analysisStatus = .uploading

        do {
            // Perform OCR
            analysisStatus = .recognizingText
            let text = try await ocrService.recognizeText(in: image)
            ocrText = text

            // Extract unique Chinese characters
            let uniqueChars = text.uniqueChineseCharacters

            // Analyze text for words AND character definitions
            analysisStatus = .lookingUpCharacters
            let analysis = await lookupService.analyzeText(text, characters: uniqueChars)

            // Store detected words
            analysisStatus = .detectingWords
            detectedWords = analysis.words

            // Build analyzed characters list
            analyzedCharacters = uniqueChars.map { char in
                let info = analysis.characters[char] ?? CharacterInfo.unknown(character: char)
                return AnalyzedCharacter(character: char, info: info)
            }

            // Find common phrases (legacy, keeping for now)
            detectedPhrases = CommonPhrases.findPhrases(in: text)

            analysisStatus = .complete

        } catch {
            errorMessage = error.localizedDescription
            errorDetails = String(describing: error)
            analysisStatus = .error(error.localizedDescription)
            showError = true
        }

        isAnalyzing = false
    }

    /// Retry analysis with the current image
    func retryAnalysis() async {
        guard let image = capturedImage else { return }
        errorMessage = nil
        errorDetails = nil
        showError = false
        await processImage(image)
    }

    /// Mark a character as saved
    func markAsSaved(_ character: String) {
        if let index = analyzedCharacters.firstIndex(where: { $0.character == character }) {
            analyzedCharacters[index].isSaved = true
        }
    }

    /// Reset for new capture
    func reset() {
        capturedImage = nil
        ocrText = ""
        detectedWords = []
        analyzedCharacters = []
        detectedPhrases = []
        showAnalysisSheet = false
        errorMessage = nil
        errorDetails = nil
        showError = false
        currentPhoto = nil
        isLoadingFromHistory = false
        analysisStatus = .idle
    }

    // MARK: - Photo History

    /// Save the current photo and analysis to history
    func savePhotoToHistory(modelContext: ModelContext) async {
        guard let image = capturedImage else { return }

        let photoId = UUID()

        // Save image to disk
        guard let imagePath = try? await PhotoStorageService.shared.saveImage(image, id: photoId) else {
            return
        }

        // Serialize analysis data
        let wordsJSON = AnalysisCacheHelper.serializeWords(detectedWords)
        let charsJSON = AnalysisCacheHelper.serializeCharacters(analyzedCharacters)

        // Create and save model
        let photo = CapturedPhoto(
            id: photoId,
            capturedAt: Date(),
            imagePath: imagePath,
            ocrText: ocrText,
            detectedWordsJSON: wordsJSON,
            analyzedCharactersJSON: charsJSON
        )

        modelContext.insert(photo)
        currentPhoto = photo
    }

    /// Load analysis from a history photo
    func loadFromHistory(_ photo: CapturedPhoto) async {
        isLoadingFromHistory = true

        // Load image from disk
        capturedImage = await PhotoStorageService.shared.loadImage(path: photo.imagePath)

        // Restore cached analysis
        ocrText = photo.ocrText
        detectedWords = AnalysisCacheHelper.deserializeWords(photo.detectedWordsJSON)
        analyzedCharacters = AnalysisCacheHelper.deserializeCharacters(photo.analyzedCharactersJSON)

        currentPhoto = photo
        showAnalysisSheet = true
        isLoadingFromHistory = false
    }

    /// Link a character card to the current photo
    func linkCharacterToPhoto(_ card: CharacterCard) {
        guard let photo = currentPhoto else { return }
        if !card.sourcePhotos.contains(where: { $0.id == photo.id }) {
            card.sourcePhotos.append(photo)
        }
    }
}
