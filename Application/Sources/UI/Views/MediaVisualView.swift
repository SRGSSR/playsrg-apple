//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGUserData
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct MediaVisualView: View {
    @Binding private(set) var media: SRGMedia?
    @StateObject private var model = MediaVisualViewModel()
    
    let scale: ImageScale
    
    static let padding: CGFloat = constant(iOS: 6, tvOS: 16)
    
    init(media: SRGMedia?, scale: ImageScale) {
        _media = .constant(media)
        self.scale = scale
    }
    
    var body: some View {
        ZStack {
            ImageView(url: model.imageUrl(for: scale))
            BlockingOverlay(media: media)
            
            if let properties = model.availabilityBadgeProperties {
                Badge(text: properties.text, color: Color(properties.color))
                    .padding([.top, .leading], Self.padding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            
            AttributesView(model: model)
                .padding([.bottom, .horizontal], Self.padding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            ProgressBar(value: model.progress)
                .opacity(model.progress != 0 ? 1 : 0)
                .frame(height: LayoutProgressBarHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .onAppear {
            model.media = media
        }
        .onChange(of: media) { newValue in
            model.media = newValue
        }
    }
    
    /// Behavior: h-exp, v-hug
    private struct AttributesView: View {
        @ObservedObject var model: MediaVisualViewModel
        
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
        
        var body: some View {
            HStack(spacing: 6) {
                Spacer()
                if model.is360 {
                    ThreeSixtyBadge()
                }
                if model.isMultiAudioAvailable {
                    MultiAudioBadge()
                }
                if canDisplayAudioDescriptionAvailability, model.isAudioDescriptionAvailable {
                    AudioDescriptionBadge()
                }
                if canDisplaySubtitleAvailability, model.areSubtitlesAvailable {
                    SubtitlesBadge()
                }
                if let youthProtectionColor = model.youthProtectionColor {
                    YouthProtectionBadge(color: youthProtectionColor)
                }
                if let duration = model.duration {
                    DurationBadge(duration: duration)
                }
            }
        }
    }
}

// MARK: Preview

struct MediaVisualView_Previews: PreviewProvider {
    private static let userDefaults: UserDefaults = {
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
