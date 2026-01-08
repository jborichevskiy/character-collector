import SwiftUI

/// Single photo thumbnail with character count badge
struct PhotoThumbnail: View {
    let photo: CapturedPhoto
    @State private var thumbnailImage: UIImage?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.theme.surface)
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Character count badge
            if photo.characters.count > 0 {
                Text("\(photo.characters.count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.theme.primary)
                    .clipShape(Capsule())
                    .offset(x: -4, y: -4)
            }
        }
        .task {
            thumbnailImage = await PhotoStorageService.shared.loadImage(path: photo.imagePath)
        }
    }
}
