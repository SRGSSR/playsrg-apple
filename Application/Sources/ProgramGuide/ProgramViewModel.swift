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
            mediaDataPublisher(for: data?.program)
                .receive(on: DispatchQueue.main)
                .assign(to: &$mediaData)
            livestreamMediaPublisher(for: data?.channel)
                .receive(on: DispatchQueue.main)
                .assign(to: &$livestreamMedia)
        }
    }
    
    @Published private var mediaData: MediaData = .empty
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
    
    private var isLive: Bool {
        guard let program = program else { return false }
        return (program.startDate...program.endDate).contains(date)
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
    
    var timeAndDate: String? {
        guard let program = program else { return nil }
        let startTime = DateFormatter.play_time.string(from: program.startDate)
        let endTime = DateFormatter.play_time.string(from: program.endDate)
        let day = DateFormatter.play_relative.string(from: program.startDate)
        return "\(startTime) - \(endTime), \(day)"
    }
    
    var timeAndDateAccessibilityLabel: String? {
        guard let program = program else { return nil }
        return String(format: "From %1$@ to %2$@", PlayAccessibilityTimeFromDate(program.startDate), PlayAccessibilityTimeFromDate(program.endDate))
            .appending(", ")
            .appending(DateFormatter.play_relativeShort.string(from: program.startDate))
    }
    
    var imageUrl: URL? {
        return program?.imageUrl(for: .medium)
    }
    
    var duration: Double? {
        guard let program = program else { return nil }
        let duration = program.endDate.timeIntervalSince(program.startDate)
        return duration > 0 ? duration : nil
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
    
    var progress: Double? {
        if isLive, let program = program {
            let progress = date.timeIntervalSince(program.startDate) / program.endDate.timeIntervalSince(program.startDate)
            return (0...1).contains(progress) ? progress : nil
        }
        else {
            return mediaData.progress
        }
    }
    
    var currentMedia: SRGMedia? {
        return isLive ? livestreamMedia : media
    }
    
    var availabilityBadgeProperties: MediaDescription.BadgeProperties? {
        guard let media = currentMedia else { return nil }
        return MediaDescription.availabilityBadgeProperties(for: media)
    }
    
    var playAction: (() -> Void)? {
        if let media = currentMedia, media.blockingReason(at: Date()) == .none {
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
        guard isLive, let media = media, media.blockingReason(at: Date()) == .none else { return nil }
        return ButtonProperties(
            icon: "start_over",
            label: NSLocalizedString("Watch from start", comment: "Button to watch some program from the start"),
            action: {
                guard let appDelegate = UIApplication.shared.delegate as? PlayAppDelegate else { return }
                if HistoryCanResumePlaybackForMedia(media) {
                    let alertController = UIAlertController(title: NSLocalizedString("Watch from start?", comment: "Resume playback alert title"),
                                                            message: NSLocalizedString("You already played this content", comment: "Resume playback alert explanation"),
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Resume playback", comment: "Alert choice to resume playback"), style: .default, handler: { _ in
                        appDelegate.rootTabBarController.play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Watch from start", comment: "Alert choice to watch content from start"), style: .default, handler: { _ in
                        appDelegate.rootTabBarController.play_presentMediaPlayer(with: media, position: .default, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Title of a cancel button"), style: .cancel, handler: nil))
                    appDelegate.rootTabBarController.play_top.present(alertController, animated: true, completion: nil)
                }
                else {
                    appDelegate.rootTabBarController.play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
                }
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
                
                self.mediaData = MediaData(media: media, watchLaterAllowedAction: added ? .remove : .add, progress: self.mediaData.progress)
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
}

// MARK: Publishers

extension ProgramViewModel {
    private func mediaDataPublisher(for program: SRGProgram?) -> AnyPublisher<MediaData, Never> {
        if let mediaUrn = program?.mediaURN {
            return Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) {
                return SRGDataProvider.current!.media(withUrn: mediaUrn)
            }
            .map { media -> AnyPublisher<MediaData, Never> in
                return Publishers.CombineLatest(Self.watchLaterPublisher(for: media), Self.historyPublisher(for: media))
                    .map { action, progress in
                        return MediaData(media: media, watchLaterAllowedAction: action, progress: progress)
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .replaceError(with: mediaData)
            .prepend(.empty)
            .eraseToAnyPublisher()
        }
        else {
            return Just(.empty)
                .eraseToAnyPublisher()
        }
    }
    
    private static func watchLaterPublisher(for media: SRGMedia) -> AnyPublisher<WatchLaterAction, Never> {
        return Publishers.PublishAndRepeat(onOutputFrom: ThrottledSignal.watchLaterUpdates(for: media.urn)) {
            return Deferred {
                Future<WatchLaterAction, Never> { promise in
                    WatchLaterAllowedActionForMediaAsync(media) { action in
                        // TODO: Bug! The block can be called several times, but the promise is fulfilled the first time only!
                        promise(.success(action))
                    }
                }
            }
        }
        .prepend(.none)
        .eraseToAnyPublisher()
    }
    
    private static func historyPublisher(for media: SRGMedia) -> AnyPublisher<Double?, Never> {
        return Publishers.PublishAndRepeat(onOutputFrom: ThrottledSignal.historyUpdates(for: media.urn)) {
            return Deferred {
                Future<Double?, Never> { promise in
                    HistoryPlaybackProgressForMediaAsync(media) { progress, completed in
                        guard completed else { return }
                        let progressValue = (progress != 0) ? Optional(Double(progress)) : nil
                        promise(.success(progressValue))
                    }
                }
            }
        }
        .prepend(nil)
        .eraseToAnyPublisher()
    }
    
    private func livestreamMediaPublisher(for channel: SRGChannel?) -> AnyPublisher<SRGMedia?, Never> {
        if let channel = channel {
            return Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) {
                return SRGDataProvider.current!.tvLivestreams(for: ApplicationConfiguration.shared.vendor)
            }
            .map { $0.first(where: { $0.channel == channel }) }
            .replaceError(with: livestreamMedia)
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
        let progress: Double?
        
        static var empty = MediaData(media: nil, watchLaterAllowedAction: .none, progress: nil)
    }
    
    /// Common button properties
    struct ButtonProperties {
        let icon: String
        let label: String
        let action: () -> Void
    }
}
