//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import Foundation

// MARK: View model

final class ProgramViewModel: ObservableObject {
    @Published var program: SRGProgram? {
        didSet {
            Self.dataPublisher(for: program)
                .receive(on: DispatchQueue.main)
                .assign(to: &$data)
        }
    }
    
    @Published private var data = Data(media: nil, watchLaterAllowedAction: .none)
    @Published private(set) var date: Date = Date()
    
    init() {
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .assign(to: &$date)
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
    
    var playAction: (() -> Void)? {
        return data.media != nil ? play : nil
    }
    
    var hasActions: Bool {
        return data.media?.show != nil
    }
    
    var episodeButtonProperties: ButtonProperties? {
        guard data.media?.show != nil else { return nil }
        return ButtonProperties(
            icon: "episodes",
            label: NSLocalizedString("More episodes", comment: "Button to access more episodes from the program detail view"),
            action: openEpisodes
        )
    }
    
    private var watchLaterAllowedAction: WatchLaterAction {
        return data.watchLaterAllowedAction
    }
    
    var watchLaterButtonProperties: ButtonProperties? {
        guard let media = data.media else { return nil }
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
 
    private func toggleWatchLater() {
        guard let media = data.media else { return }
        WatchLaterToggleMedia(media) { added, error in
            guard error == nil else { return }
            
            let analyticsTitle = added ? AnalyticsTitle.watchLaterAdd : AnalyticsTitle.watchLaterRemove
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.source = AnalyticsSource.button.rawValue
            labels.value = media.urn
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: analyticsTitle.rawValue, labels: labels)
            
            self.data = Data(media: media, watchLaterAllowedAction: added ? .remove : .add)
        }
    }
    
    private func openEpisodes() {
        guard let show = data.media?.show, let appDelegate = UIApplication.shared.delegate as? PlayAppDelegate else { return }
        let showViewController = SectionViewController.showViewController(for: show)
        appDelegate.rootTabBarController.pushViewController(showViewController, animated: false)
        appDelegate.window.play_dismissAllViewControllers(animated: true, completion: nil)
    }
    
    private func play() {
        guard let media = data.media, let appDelegate = UIApplication.shared.delegate as? PlayAppDelegate else { return }
        appDelegate.rootTabBarController.play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
    }
    
    private static func dataPublisher(for program: SRGProgram?) -> AnyPublisher<Data, Never> {
        if let mediaUrn = program?.mediaURN {
            return SRGDataProvider.current!.media(withUrn: mediaUrn)
                .receive(on: DispatchQueue.main)
                .map { media in
                    return Publishers.PublishAndRepeat(onOutputFrom: ThrottledSignal.watchLaterUpdates(for: media.urn)) {
                        return Just(Data(media: media, watchLaterAllowedAction: WatchLaterAllowedActionForMedia(media)))
                    }
                }
                .switchToLatest()
                .replaceError(with: Data(media: nil, watchLaterAllowedAction: .none))
                .eraseToAnyPublisher()
        }
        else {
            return Just(Data(media: nil, watchLaterAllowedAction: .none))
                .eraseToAnyPublisher()
        }
    }
}

// MARK: Types

extension ProgramViewModel {
    struct Data {
        let media: SRGMedia?
        let watchLaterAllowedAction: WatchLaterAction
    }
    
    struct ButtonProperties {
        let icon: String
        let label: String
        let action: () -> Void
    }
}
