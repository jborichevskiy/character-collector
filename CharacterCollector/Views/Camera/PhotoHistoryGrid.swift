import SwiftUI
import SwiftData

/// Horizontal scrolling grid of captured photo thumbnails
struct PhotoHistoryGrid: View {
    let photos: [CapturedPhoto]
    let onPhotoTap: (CapturedPhoto) -> Void

    private let rows = [
        GridItem(.fixed(80)),
        GridItem(.fixed(80))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Photos")
                    .font(.headline)
                    .foregroundStyle(Color.theme.text)

                Spacer()

                Text("\(photos.count)")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textMuted)
            }
            .padding(.horizontal)

            if photos.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, spacing: 8) {
                        ForEach(photos) { photo in
                            PhotoThumbnail(photo: photo)
                                .onTapGesture { onPhotoTap(photo) }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 168) // 2 rows of 80 + spacing
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "photo.stack")
                    .font(.title2)
                    .foregroundStyle(Color.theme.textMuted)
                Text("No photos yet")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textMuted)
            }
            .padding(.vertical, 40)
            Spacer()
        }
    }
}
