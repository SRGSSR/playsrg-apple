//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Collections
import Combine
import Foundation
import SRGDataProviderModel

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
    
    @Published private var mediaData: MediaData = .empty
    @Published private var livestreamMedia: SRGMedia?
    
    @Published private(set) var date = Date()
    
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
        return media?.show ?? program?.show
    }
    
    private var channel: SRGChannel? {
        return data?.channel
    }
    
    private var isLive: Bool {
        guard let program else { return false }
        return (program.startDate...program.endDate).contains(date)
    }
    
    var title: String? {
        return program?.title
    }
    
    var subtitle: String? {
        return program?.subtitle ?? program?.lead
    }
    
    var summary: String? {
        if program?.subtitle != nil, let lead = program?.lead {
            if let summary = program?.summary {
                return "\(lead)\n\n\(summary)"
            }
            else {
                return lead
            }
        }
        else {
            return program?.summary
        }
    }
    
    var timeAndDate: String? {
        guard let program else { return nil }
        let startTime = DateFormatter.play_time.string(from: program.startDate)
        let endTime = DateFormatter.play_time.string(from: program.endDate)
        let day = DateFormatter.play_relativeFull.string(from: program.startDate)
        return "\(startTime) - \(endTime), \(day)"
    }
    
    var timeAndDateAccessibilityLabel: String? {
        guard let program else { return nil }
        return String(format: PlaySRGAccessibilityLocalizedString("From %1$@ to %2$@", comment: "Text providing program time information. First placeholder is the start time, second is the end time."), PlayAccessibilityTimeFromDate(program.startDate), PlayAccessibilityTimeFromDate(program.endDate))
            .appending(", ")
            .appending(DateFormatter.play_relativeFull.string(from: program.startDate))
    }
    
    var youthProtectionColor: SRGYouthProtectionColor? {
        let youthProtectionColor = program?.youthProtectionColor
        return youthProtectionColor != SRGYouthProtectionColor.none ? youthProtectionColor : nil
    }
    
    var imageUrl: URL? {
        return url(for: program?.image, size: .medium)
    }
    
    private var duration: Double? {
        guard let program else { return nil }
        let duration = program.endDate.timeIntervalSince(program.startDate)
        return duration > 0 ? duration : nil
    }
    
    private var production: String? {
        let year = program?.productionYear?.stringValue
        let production = [program?.productionCountry, year]
            .compactMap { $0 }
            .joined(separator: " ")
        return !production.isEmpty ? production : nil
    }
    
    var durationAndProduction: String? {
        guard let program else { return nil }
        let durationString = duration != nil ? PlayFormattedMinutes(duration!) : nil
        let durationAndProduction = [durationString, production, program.genre]
            .compactMap { $0 }
            .joined(separator: " · ")
        return !durationAndProduction.isEmpty ? durationAndProduction : nil
    }
    
    var hasAttributes: Bool {
        return hasAudioDescription || hasDolbyDigital || hasMultiAudio || hasSignLanguage || hasSubtitles
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
    
    var hasSignLanguage: Bool {
        return program?.signLanguageAvailable ?? false
    }
    
    var hasDolbyDigital: Bool {
        return program?.dolbyDigitalAvailable ?? false
    }
    
    var crewMembersDatas: [CrewMembersData]? {
        guard let crewMembers = program?.crewMembers, !crewMembers.isEmpty else { return nil }
        return OrderedDictionary(grouping: crewMembers, by: { $0.role }).map { role, crewMembers in
            return CrewMembersData(role: role, crewMembers: crewMembers)
        }
    }
    
    var imageCopyright: String? {
        guard let imageCopyright = program?.imageCopyright else { return nil }
        return String(format: NSLocalizedString("Image credit: %@", comment: "Image copyright introductory label"), imageCopyright)
    }
    
    var progress: Double? {
        if isLive, let program {
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
                guard let tabBarController = UIApplication.shared.mainTabBarController else { return }
                tabBarController.play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
            }
        }
        else {
            return nil
        }
    }
    
    var hasActions: Bool {
        return watchFromStartButtonProperties != nil || watchLaterButtonProperties != nil
    }
    
    var watchFromStartButtonProperties: ButtonProperties? {
        guard isLive, let media, media.blockingReason(at: Date()) == .none else { return nil }
        return ButtonProperties(
            icon: "start_over",
            label: NSLocalizedString("Watch from start", comment: "Button to watch some program from the start"),
            action: {
                guard let tabBarController = UIApplication.shared.mainTabBarController else { return }
                if HistoryCanResumePlaybackForMedia(media) {
                    let alertController = UIAlertController(title: NSLocalizedString("Watch from start?", comment: "Resume playback alert title"),
                                                            message: NSLocalizedString("You already played this content.", comment: "Resume playback alert explanation"),
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Resume", comment: "Alert choice to resume playback"), style: .default, handler: { _ in
                        tabBarController.play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Watch from start", comment: "Alert choice to watch content from start"), style: .default, handler: { _ in
                        tabBarController.play_presentMediaPlayer(with: media, position: .default, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Title of a cancel button"), style: .cancel, handler: nil))
                    tabBarController.play_top.present(alertController, animated: true, completion: nil)
                }
                else {
                    tabBarController.play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
                }
            }
        )
    }
    
    var showButtonProperties: ShowButtonProperties? {
        guard let show else { return nil }
        return ShowButtonProperties(
            show: show,
            isFavorite: FavoritesContainsShow(show),
            action: {
                guard let tabBarController = UIApplication.shared.mainTabBarController,
                      let window = UIApplication.shared.mainWindow else {
                    return
                }
                let showViewController = SectionViewController.showViewController(for: show)
                tabBarController.pushViewController(showViewController, animated: false)
                window.play_dismissAllViewControllers(animated: true, completion: nil)
            }
        )
    }
    
    private var watchLaterAllowedAction: WatchLaterAction {
        return mediaData.watchLaterAllowedAction
    }
    
    var watchLaterButtonProperties: ButtonProperties? {
        guard !isLive, let media else { return nil }
        
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
    private static func mediaDataPublisher(for program: SRGProgram?) -> AnyPublisher<MediaData, Never> {
        if let mediaUrn = program?.mediaURN {
            return Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) {
                return SRGDataProvider.current!.media(withUrn: mediaUrn)
                    .catch { _ in
                        return Empty()
                    }
            }
            .map { media in
                return Publishers.CombineLatest(UserDataPublishers.laterAllowedActionPublisher(for: media), UserDataPublishers.playbackProgressPublisher(for: media))
                    .map { action, progress in
                        return MediaData(media: media, watchLaterAllowedAction: action, progress: progress)
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .prepend(.empty)
            .eraseToAnyPublisher()
        }
        else {
            return Just(.empty)
                .eraseToAnyPublisher()
        }
    }
    
    private static func livestreamMediaPublisher(for channel: SRGChannel?) -> AnyPublisher<SRGMedia?, Never> {
        if let channel {
            return Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) {
                return SRGDataProvider.current!.tvLivestreams(for: channel.vendor)
                    .catch { _ in
                        return Empty()
                    }
            }
            .map { $0.first(where: { $0.channel == channel }) }
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
    
    /// Data related to the program crew members
    struct CrewMembersData: Identifiable {
        let role: String?
        let names: [String]
        
        var id: String? {
            return role
        }
        
        init(role: String?, crewMembers: [SRGCrewMember]) {
            self.role = role
            self.names = crewMembers.map { crewMember in
                if let characterName = crewMember.characterName {
                    return "\(crewMember.name) (\(characterName))"
                }
                else {
                    return crewMember.name
                }
            }
        }
        
        var accessibilityLabel: String {
            return "\(role ?? "") \(names.joined(separator: ", "))"
        }
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
    
    /// Show button properties
    struct ShowButtonProperties {
        let show: SRGShow
        let isFavorite: Bool
        let action: () -> Void
    }
}
