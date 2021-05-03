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
    
    static let padding: CGFloat = constant(iOS: 6, tvOS: 16)
    static let spacing: CGFloat = 6
    
    @State private var progress: Double = 0
    @State private var taskHandle: String?
    
    @AppStorage(PlaySRGSettingSubtitleAvailabilityDisplayed) var isSubtitleAvailabilityDisplayed = false
    @AppStorage(PlaySRGSettingAudioDescriptionAvailabilityDisplayed) var isAudioDescriptionAvailabilityDisplayed = false
    
    @Accessibility(\.isVoiceOverRunning) private var isVoiceOverRunning
    
    private var canDisplaySubtitleAvailability: Bool {
        guard !ApplicationConfiguration.shared.isSubtitleAvailabilityHidden else { return false }
        
        return isVoiceOverRunning || isSubtitleAvailabilityDisplayed
    }
    
    private var canDisplayAudioDescriptionAvailability: Bool {
        guard !ApplicationConfiguration.shared.isAudioDescriptionAvailabilityHidden else { return false }
        
        return isVoiceOverRunning || isAudioDescriptionAvailabilityDisplayed
    }
    
    private func updateProgress() {
        HistoryPlaybackProgressAsyncCancel(taskHandle)
        taskHandle = HistoryPlaybackProgressForMediaMetadataAsync(media, { progress = Double($0) })
    }
    
    var body: some View {
        ZStack {
            ImageView(url: media?.imageUrl(for: scale))
            BlockingOverlay(media: media)
            
            if let media = media, let availabilityBadgeProperties = MediaDescription.availabilityBadgeProperties(for: media) {
                Badge(text: availabilityBadgeProperties.text, color: availabilityBadgeProperties.color)
                    .padding([.top, .leading], Self.padding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            
            HStack(spacing: Self.spacing) {
                if media?.presentation == .presentation360 {
                    ThreeSixtyBadge()
                }
                Spacer()
                if canDisplayAudioDescriptionAvailability, let media = media, media.play_isAudioDescriptionAvailable {
                    AudioDescriptionBadge()
                }
                if canDisplaySubtitleAvailability, let media = media, media.play_areSubtitlesAvailable {
                    SubtitlesBadge()
                }
                YouthProtectionBadge(color: media?.youthProtectionColor)
                if let duration = MediaDescription.duration(for: media) {
                    DurationBadge(text: duration)
                }
            }
            .padding([.bottom, .horizontal], Self.padding)
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
    static let userDefaults: UserDefaults = {
        let userDefaults = UserDefaults()
        userDefaults.setValue(true, forKey: PlaySRGSettingSubtitleAvailabilityDisplayed)
        userDefaults.setValue(true, forKey: PlaySRGSettingAudioDescriptionAvailabilityDisplayed)
        return userDefaults
    }()
    
    static var previews: some View {
        Group {
            MediaVisualView(media: Mock.media(.standard), scale: .small)
            MediaVisualView(media: Mock.media(.rich), scale: .small)
            MediaVisualView(media: Mock.media(.nineSixteen), scale: .small)
            MediaVisualView(media: Mock.media(.blocked), scale: .small)
        }
        .frame(width: 600, height: 500)
        .previewLayout(.sizeThatFits)
        .defaultAppStorage(userDefaults)
    }
}
