//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import Foundation

// MARK: View model

final class ProgramViewModel: ObservableObject {
    @Published var data: Data? {
        didSet {
            Self.mediaDataPublisher(for: data?.program)
                .receive(on: DispatchQueue.main)
                .assign(to: &$mediaData)
            Self.livestreamMediaPublisher(for: data?.channel)
                .receive(on: DispatchQueue.main)
                .assign(to: &$livestreamMedia)
        }
    }
    
    @Published private var mediaData = MediaData(media: nil, watchLaterAllowedAction: .none)
    @Published private var livestreamMedia: SRGMedia?
    
    @Published private(set) var date: Date = Date()
    
    init() {
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .assign(to: &$date)
    }
    
    private var program: SRGProgram? {
        return data?.program
    }
    
    private var media: SRGMedia? {
        return mediaData.media
    }
    
    private var show: SRGShow? {
        return media?.show
    }
    
    private var channel: SRGChannel? {
        return data?.channel
    }
    
    var title: String? {
        return program?.title
    }
    
    var lead: String? {
        return program?.lead
    }
    
    var summary: String? {
        return program?.summary
    }
    
    var formattedTimeAndDate: String? {
        guard let program = program else { return nil }
        let startTime = DateFormatter.play_time.string(from: program.startDate)
        let endTime = DateFormatter.play_time.string(from: program.endDate)
        let day = DateFormatter.play_relative.string(from: program.startDate)
        return "\(startTime) - \(endTime), \(day)"
    }
    
    var imageUrl: URL? {
        return program?.imageUrl(for: .medium)
    }
    
    var duration: Double? {
        guard let program = program else { return nil }
        let duration = program.endDate.timeIntervalSince(program.startDate)
        return duration > 0 ? duration : nil
    }
    
    var progress: Double? {
        guard let program = program else { return nil }
        let progress = date.timeIntervalSince(program.startDate) / program.endDate.timeIntervalSince(program.startDate)
        return (0...1).contains(progress) ? progress : nil
    }
    
    private var isLive: Bool {
        return progress != nil
    }
    
    var hasMultiAudio: Bool {
        return program?.alternateAudioAvailable ?? false
    }
    
    var hasAudioDescription: Bool {
        return program?.audioDescriptionAvailable ?? false
    }
    
    var hasSubtitles: Bool {
        return program?.subtitlesAvailable ?? false
    }
    
    var imageCopyright: String? {
        guard let imageCopyright = program?.imageCopyright else { return nil }
        return String(format: NSLocalizedString("Image credit: %@", comment: "Image copyright introductory label"), imageCopyright)
    }
    
    var availabilityBadgeProperties: MediaDescription.BadgeProperties? {
        guard let media = media else { return nil }
        return MediaDescription.availabilityBadgeProperties(for: media)
    }
    
    var playAction: (() -> Void)? {
        if isLive, let livestreamMedia = livestreamMedia {
            return {
                guard let appDelegate = UIApplication.shared.delegate as? PlayAppDelegate else { return }
                appDelegate.rootTabBarController.play_presentMediaPlayer(with: livestreamMedia, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
            }
        }
        else if let media = media {
            return {
                guard let appDelegate = UIApplication.shared.delegate as? PlayAppDelegate else { return }
                appDelegate.rootTabBarController.play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
            }
        }
        else {
            return nil
        }
    }
    
    var hasActions: Bool {
        return watchFromStartButtonProperties != nil || episodeButtonProperties != nil || watchLaterButtonProperties != nil
    }
    
    var watchFromStartButtonProperties: ButtonProperties? {
        guard isLive, let media = media else { return nil }
        return ButtonProperties(
            icon: "start_over",
            label: NSLocalizedString("Watch from start", comment: "Button to watch some program from the start"),
            action: {
                guard let appDelegate = UIApplication.shared.delegate as? PlayAppDelegate else { return }
                appDelegate.rootTabBarController.play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
            }
        )
    }
    
    var episodeButtonProperties: ButtonProperties? {
        guard let show = show else { return nil }
        return ButtonProperties(
            icon: "episodes",
            label: NSLocalizedString("More episodes", comment: "Button to access more episodes from the program detail view"),
            action: {
                guard let appDelegate = UIApplication.shared.delegate as? PlayAppDelegate else { return }
                let showViewController = SectionViewController.showViewController(for: show)
                appDelegate.rootTabBarController.pushViewController(showViewController, animated: false)
                appDelegate.window.play_dismissAllViewControllers(animated: true, completion: nil)
            }
        )
    }
    
    private var watchLaterAllowedAction: WatchLaterAction {
        return mediaData.watchLaterAllowedAction
    }
    
    var watchLaterButtonProperties: ButtonProperties? {
        guard !isLive, let media = media else { return nil }
        
        func toggleWatchLater() {
            WatchLaterToggleMedia(media) { added, error in
                guard error == nil else { return }
                
                let analyticsTitle = added ? AnalyticsTitle.watchLaterAdd : AnalyticsTitle.watchLaterRemove
                let labels = SRGAnalyticsHiddenEventLabels()
                labels.source = AnalyticsSource.button.rawValue
                labels.value = media.urn
                SRGAnalyticsTracker.shared.trackHiddenEvent(withName: analyticsTitle.rawValue, labels: labels)
                
                self.mediaData = MediaData(media: media, watchLaterAllowedAction: added ? .remove : .add)
            }
        }
        
        switch watchLaterAllowedAction {
        case .add:
            switch media.mediaType {
            case .audio:
                return ButtonProperties(
                    icon: "watch_later",
                    label: NSLocalizedString("Listen later", comment: "Button label in program detail view to add an audio to the later list"),
                    action: toggleWatchLater
                )
            default:
                return ButtonProperties(
                    icon: "watch_later",
                    label: NSLocalizedString("Watch later", comment: "Button label in program detail view to add a video to the later list"),
                    action: toggleWatchLater
                )
            }
        case .remove:
            return ButtonProperties(
                icon: "watch_later_full",
                label: NSLocalizedString("Later", comment: "Watch later or listen later button label in program detail view when a media is in the later list"),
                action: toggleWatchLater
            )
        default:
            return nil
        }
    }
    
    private static func mediaDataPublisher(for program: SRGProgram?) -> AnyPublisher<MediaData, Never> {
        if let mediaUrn = program?.mediaURN {
            return SRGDataProvider.current!.media(withUrn: mediaUrn)
                .receive(on: DispatchQueue.main)        // `WatchLaterAllowedActionForMedia` must currently be called on the main thread
                .map { media in
                    return Publishers.PublishAndRepeat(onOutputFrom: ThrottledSignal.watchLaterUpdates(for: media.urn)) {
                        return Just(MediaData(media: media, watchLaterAllowedAction: WatchLaterAllowedActionForMedia(media)))
                    }
                }
                .switchToLatest()
                .replaceError(with: MediaData(media: nil, watchLaterAllowedAction: .none))
                .prepend(MediaData(media: nil, watchLaterAllowedAction: .none))
                .eraseToAnyPublisher()
        }
        else {
            return Just(MediaData(media: nil, watchLaterAllowedAction: .none))
                .eraseToAnyPublisher()
        }
    }
    
    private static func livestreamMediaPublisher(for channel: SRGChannel?) -> AnyPublisher<SRGMedia?, Never> {
        if let channel = channel {
            return SRGDataProvider.current!.tvLivestreams(for: ApplicationConfiguration.shared.vendor)
                .map { $0.first(where: { $0.channel == channel }) }
                .replaceError(with: nil)
                .prepend(nil)
                .eraseToAnyPublisher()
        }
        else {
            return Just(nil)
                .eraseToAnyPublisher()
        }
    }
}

// MARK: Types

extension ProgramViewModel {
    /// Input data for the model
    struct Data: Hashable {
        let program: SRGProgram
        let channel: SRGChannel
    }
    
    /// Data related to the media stored by the model
    private struct MediaData {
        let media: SRGMedia?
        let watchLaterAllowedAction: WatchLaterAction
    }
    
    /// Common button properties
    struct ButtonProperties {
        let icon: String
        let label: String
        let action: () -> Void
    }
}
