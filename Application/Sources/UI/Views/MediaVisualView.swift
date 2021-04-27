//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGUserData
import SwiftUI

/// Behavior: h-exp, v-exp
struct MediaVisualView: View {
    let media: SRGMedia?
    let scale: ImageScale
    
    @State private var progress: Double = 0
    @State private var taskHandle: String?
    
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
            ImageView(url: media?.imageUrl(for: scale))
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
                    .frame(height: LayoutProgressBarHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .onAppear {
            updateProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange)) { notification in
            if let updatedUrns = notification.userInfo?[SRGHistoryEntriesUidsKey] as? Set<String>,
               let media = media, updatedUrns.contains(media.urn) {
                updateProgress()
            }
        }
    }
}

struct MediaVisualView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MediaVisualView(media: Mock.media(.standard), scale: .small)
            MediaVisualView(media: Mock.media(.rich), scale: .small)
            MediaVisualView(media: Mock.media(.nineSixteen), scale: .small)
            MediaVisualView(media: Mock.media(.blocked), scale: .small)
        }
        .frame(width: 500, height: 500)
        .previewLayout(.sizeThatFits)
    }
}
