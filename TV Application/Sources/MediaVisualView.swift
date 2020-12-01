//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGUserData
import SwiftUI

struct MediaVisualView: View {
    let media: SRGMedia?
    let scale: ImageScale
    let contentMode: ContentMode
    
    @State private var progress: Double = 0
    @State private var taskHandle: String? = nil
    
    init(media: SRGMedia?, scale: ImageScale, contentMode: ContentMode = .fit) {
        self.media = media
        self.scale = scale
        self.contentMode = contentMode
    }
    
    private var imageUrl: URL? {
        return media?.imageURL(for: .width, withValue: SizeForImageScale(scale).width, type: .default)
    }
    
    private var youthProtectionLogoImage: UIImage? {
        guard let youthProtectionColor = media?.youthProtectionColor else { return nil }
        return YouthProtectionImageForColor(youthProtectionColor)
    }
    
    private func updateProgress() {
        HistoryPlaybackProgressAsyncCancel(taskHandle)
        taskHandle = HistoryPlaybackProgressForMediaMetadataAsync(media, { progress = Double($0) })
    }
    
    var body: some View {
        ZStack {
            ImageView(url: imageUrl, contentMode: contentMode)
            BlockingOverlay(media: media)
            
            HStack(spacing: 4) {
                if media?.presentation == .presentation360 {
                    Image("360_media-25")
                        .foregroundColor(.white)
                }
                Spacer()
                if let youthProtectionLogoImage = youthProtectionLogoImage {
                    Image(uiImage: youthProtectionLogoImage)
                }
                DurationLabel(media: media)
            }
            .padding([.leading, .trailing, .bottom], 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            if let progress = progress {
                ProgressBar(value: progress)
                    .opacity(progress != 0 ? 1 : 0)
                    .frame(height: 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            
            if let media = media {
                AvailabilityBadge(media: media)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .onAppear {
            updateProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange)) { notification in
            if let updatedUrns = notification.userInfo?[SRGHistoryEntriesUidsKey] as? Set<String>,
               let media = media,
               updatedUrns.contains(media.urn) {
                updateProgress()
            }
        }
    }
}
