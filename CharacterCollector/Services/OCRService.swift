import UIKit
import Foundation

/// Service for performing OCR on images using Claude's vision API
actor OCRService {

    private let apiKey = anthropicAPIKey
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    enum OCRError: Error, LocalizedError {
        case invalidImage
        case noTextFound
        case recognitionFailed(String)
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not process the image"
            case .noTextFound:
                return "No Chinese text found in image"
            case .recognitionFailed(let message):
                return "Recognition failed: \(message)"
            case .apiError(let message):
                return "API error: \(message)"
            }
        }
    }

    /// Recognize Chinese text in an image using Claude's vision API
    func recognizeText(in image: UIImage) async throws -> String {
        // Resize image if needed to reduce API costs
        let resizedImage = resizeImageIfNeeded(image, maxDimension: 1024)

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw OCRError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        // Build the API request
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": """
                            Look at this image and extract ALL Chinese characters you can see.

                            Return ONLY the Chinese characters, nothing else. No translations, no pinyin, no explanations.
                            If you see the same character multiple times, include it only once.
                            Separate distinct words or phrases with spaces.

                            If there are no Chinese characters in the image, respond with exactly: NO_CHINESE_TEXT
                            """
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OCRError.apiError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OCRError.apiError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        // Parse the response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw OCRError.apiError("Could not parse response")
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText == "NO_CHINESE_TEXT" || trimmedText.isEmpty {
            throw OCRError.noTextFound
        }

        return trimmedText
    }

    /// Resize image if it exceeds max dimension (to reduce API costs)
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let scale: CGFloat
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}
