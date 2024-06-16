//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class MediaVisualViewModel: ObservableObject {
    @Published var media: SRGMedia?
    @Published private(set) var progress: Double?

    init() {
        // Drop initial values; relevant values are first assigned when the view appears
        $media
            .dropFirst()
            .map { media in
                guard let media else {
                    return Just(nil as Double?).eraseToAnyPublisher()
                }
                return UserDataPublishers.playbackProgressPublisher(for: media)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$progress)
    }

    func imageUrl(for size: SRGImageSize) -> URL? {
        return url(for: media?.image, size: size)
    }

    var availabilityBadgeProperties: MediaDescription.BadgeProperties? {
        guard let media else { return nil }
        return MediaDescription.availabilityBadgeProperties(for: media)
    }

    var is360: Bool {
        return media?.presentation == .presentation360
    }

    var isMultiAudioAvailable: Bool {
        guard let media else { return false }
        return media.play_isMultiAudioAvailable
    }

    var isAudioDescriptionAvailable: Bool {
        guard let media else { return false }
        return media.play_isAudioDescriptionAvailable
    }

    var areSubtitlesAvailable: Bool {
        guard let media else { return false }
        return media.play_areSubtitlesAvailable
    }

    var youthProtectionColor: SRGYouthProtectionColor? {
        let youthProtectionColor = media?.youthProtectionColor
        return youthProtectionColor != SRGYouthProtectionColor.none ? youthProtectionColor : nil
    }

    var duration: Double? {
        guard let media else { return nil }
        return MediaDescription.duration(for: media)
    }
}
