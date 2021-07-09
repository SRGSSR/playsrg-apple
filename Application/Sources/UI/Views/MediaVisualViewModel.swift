//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

class MediaVisualViewModel: ObservableObject {
    @Published var media: SRGMedia? {
        didSet {
            Self.progressPublisher(for: media)
                .assign(to: &$progress)
        }
    }
    
    @Published private(set) var progress: Double = 0
    
    func imageUrl(for scale: ImageScale) -> URL? {
        return media?.imageUrl(for: scale)
    }
    
    var availabilityBadgeProperties: (text: String, color: UIColor)? {
        guard let media = media else { return nil }
        return MediaDescription.availabilityBadgeProperties(for: media)
    }
    
    var is360: Bool {
        return media?.presentation == .presentation360
    }
    
    var isMultiAudioAvailable: Bool {
        guard let media = media else { return false }
        return media.play_isMultiAudioAvailable
    }
    
    var isAudioDescriptionAvailable: Bool {
        guard let media = media else { return false }
        return media.play_isAudioDescriptionAvailable
    }
    
    var areSubtitlesAvailable: Bool {
        guard let media = media else { return false }
        return media.play_areSubtitlesAvailable
    }
    
    var youthProtectionColor: SRGYouthProtectionColor? {
        return media?.youthProtectionColor
    }
    
    var duration: Double? {
        guard let media = media else { return nil }
        return MediaDescription.duration(for: media)
    }
    
    private static func progressPublisher(for media: SRGMedia?) -> AnyPublisher<Double, Never> {
        if let media = media {
            return Publishers.PublishAndRepeat(onOutputFrom: Signal.historyUpdate(for: media.urn)) {
                return Deferred {
                    Future<Double, Never> { promise in
                        HistoryPlaybackProgressForMediaMetadataAsync(media) { progress in
                            promise(.success(Double(progress)))
                        }
                    }
                }
            }
            .eraseToAnyPublisher()
        }
        else {
            return Just(0)
                .eraseToAnyPublisher()
        }
    }
}
