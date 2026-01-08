import Foundation
import SwiftData

@Model
final class CapturedPhoto {
    var id: UUID
    var capturedAt: Date
    var imagePath: String
    var ocrText: String
    var detectedWordsJSON: String
    var analyzedCharactersJSON: String

    @Relationship(inverse: \CharacterCard.sourcePhotos)
    var characters: [CharacterCard]

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        imagePath: String = "",
        ocrText: String = "",
        detectedWordsJSON: String = "[]",
        analyzedCharactersJSON: String = "[]"
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.imagePath = imagePath
        self.ocrText = ocrText
        self.detectedWordsJSON = detectedWordsJSON
        self.analyzedCharactersJSON = analyzedCharactersJSON
        self.characters = []
    }
}
