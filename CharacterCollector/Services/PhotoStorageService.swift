import UIKit
import Foundation

/// Service for storing and retrieving captured photos
actor PhotoStorageService {

    static let shared = PhotoStorageService()

    private let fileManager = FileManager.default
    private let photosDirectory: URL

    private init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        photosDirectory = documentsPath.appendingPathComponent("CapturedPhotos", isDirectory: true)

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
    }

    /// Save an image and return the relative path
    func saveImage(_ image: UIImage, id: UUID) async throws -> String {
        let filename = "\(id.uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)

        // Resize for storage efficiency
        let resizedImage = resizeImageIfNeeded(image, maxDimension: 1200)

        guard let data = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw PhotoStorageError.compressionFailed
        }

        try data.write(to: fileURL)
        return filename
    }

    /// Load an image from the relative path
    func loadImage(path: String) async -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    /// Delete an image file
    func deleteImage(path: String) async throws {
        let fileURL = photosDirectory.appendingPathComponent(path)
        try fileManager.removeItem(at: fileURL)
    }

    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let scale = size.width > size.height
            ? maxDimension / size.width
            : maxDimension / size.height
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    enum PhotoStorageError: Error, LocalizedError {
        case compressionFailed
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .compressionFailed: return "Failed to compress image"
            case .saveFailed: return "Failed to save image"
            }
        }
    }
}
