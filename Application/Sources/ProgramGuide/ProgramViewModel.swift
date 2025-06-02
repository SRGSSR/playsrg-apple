//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Collections
import Combine
import EventKit
import EventKitUI
import Foundation
import SRGDataProviderModel

// MARK: View model

final class ProgramViewModel: ObservableObject {
    @Published var data: ProgramAndChannel? {
        didSet {
            Self.mediaDataPublisher(for: data?.program.wrappedValue)
                .receive(on: DispatchQueue.main)
                .assign(to: &$mediaData)
            Self.livestreamMediaPublisher(for: data?.channel.wrappedValue)
                .receive(on: DispatchQueue.main)
                .assign(to: &$livestreamMedia)
            eventEditViewDelegateObject.channel = data?.channel.wrappedValue
        }
    }

    @Published private var mediaData: MediaData = .empty
    @Published private var livestreamMedia: SRGMedia?

    @Published private(set) var date = Date()

    private let eventEditViewDelegateObject = EventEditViewDelegateObject()

    init() {
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .assign(to: &$date)
    }

    private var program: SRGProgram? {
        data?.program.wrappedValue
    }

    private var media: SRGMedia? {
        mediaData.media
    }

    private var show: SRGShow? {
        media?.show ?? program?.show
    }

    private var channel: SRGChannel? {
        data?.channel.wrappedValue
    }

    private var isLive: Bool {
        guard let program else { return false }
        return (program.startDate ... program.endDate).contains(date)
    }

    var title: String? {
        program?.title
    }

    var subtitle: String? {
        program?.subtitle
    }

    var lead: String? {
        program?.lead
    }

    var summary: String? {
        program?.summary
    }

    var timeAndDate: String? {
        guard let program = data?.program else { return nil }
        let startTime = DateFormatter.play_time.string(from: program.wrappedValue.startDate)
        let endTime = DateFormatter.play_time.string(from: program.extendedEndDate)
        let day = DateFormatter.play_relativeFullDate.string(from: program.wrappedValue.startDate)
        return "\(startTime) - \(endTime) · \(day)"
    }

    var timeAndDateAccessibilityLabel: String? {
        guard let program else { return nil }
        return String(format: PlaySRGAccessibilityLocalizedString("From %1$@ to %2$@", comment: "Text providing program time information. First placeholder is the start time, second is the end time."), PlayAccessibilityTimeFromDate(program.startDate), PlayAccessibilityTimeFromDate(program.endDate))
            .appending(", ")
            .appending(DateFormatter.play_relativeFullDate.string(from: program.startDate))
    }

    private var seasonNumber: NSNumber? {
        guard let seasonNumber = program?.seasonNumber else { return nil }
        return seasonNumber.intValue > 0 ? seasonNumber : nil
    }

    private var episodeNumber: NSNumber? {
        guard let episodeNumber = program?.episodeNumber else { return nil }
        return episodeNumber.intValue > 0 ? episodeNumber : nil
    }

    var serie: String? {
        let seaon = seasonNumber != nil ? "\(NSLocalizedString("Season", comment: "Season of a serie")) \(seasonNumber!)" : nil
        let episode = episodeNumber != nil ? "\(NSLocalizedString("Episode", comment: "Episode of a serie")) \(episodeNumber!)" : nil
        let serie = [seaon, episode]
            .compactMap { $0 }
            .joined(separator: " · ")
        return !serie.isEmpty ? serie : nil
    }

    var youthProtectionColor: SRGYouthProtectionColor? {
        let youthProtectionColor = program?.youthProtectionColor
        return youthProtectionColor != SRGYouthProtectionColor.none ? youthProtectionColor : nil
    }

    var imageUrl: URL? {
        data?.programGuideImageUrl(size: .medium)
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

    var badgesListData: BadgeList.Data? {
        guard let program else { return nil }
        return BadgeList.data(for: program)
    }

    var crewMembersDatas: [CrewMembersData]? {
        guard let crewMembers = program?.crewMembers, !crewMembers.isEmpty else { return nil }
        return OrderedDictionary(grouping: crewMembers, by: { $0.role }).map { role, crewMembers in
            CrewMembersData(role: role, crewMembers: crewMembers)
        }
    }

    var imageCopyright: String? {
        guard let imageCopyright = program?.imageCopyright else { return nil }
        return String(format: NSLocalizedString("Image credit: %@", comment: "Image copyright introductory label"), imageCopyright)
    }

    var progress: Double? {
        if isLive, let program {
            let progress = date.timeIntervalSince(program.startDate) / program.endDate.timeIntervalSince(program.startDate)
            return (0 ... 1).contains(progress) ? progress : nil
        } else {
            return mediaData.progress
        }
    }

    var currentMedia: SRGMedia? {
        isLive ? livestreamMedia : media
    }

    var availabilityBadgeProperties: MediaDescription.BadgeProperties? {
        if isLive {
            MediaDescription.liveBadgeProperties()
        } else if let media = currentMedia {
            MediaDescription.availabilityBadgeProperties(for: media)
        } else {
            nil
        }
    }

    var playAction: (() -> Void)? {
        if let media = currentMedia, media.blockingReason(at: Date()) == .none,
           let tabBarController = UIApplication.shared.mainTabBarController {
            { [self] in
                if let data {
                    if media.contentType == .livestream {
                        AnalyticsClickEvent.tvGuidePlayLivestream(program: data.program.wrappedValue, channel: data.channel.wrappedValue).send()
                    } else {
                        AnalyticsClickEvent.tvGuidePlayMedia(media: media, programIsLive: isLive, channel: data.channel.wrappedValue).send()
                    }
                }

                tabBarController.dismissAndPresentMediaPlayer(with: media, position: nil)
            }
        } else {
            nil
        }
    }

    var hasActions: Bool {
        watchFromStartButtonProperties != nil || watchLaterButtonProperties != nil || calendarButtonProperties != nil
    }

    var watchFromStartButtonProperties: ButtonProperties? {
        guard isLive, let media, media.blockingReason(at: Date()) == .none else { return nil }

        let data = data
        let analyticsClickEvent = data != nil ? AnalyticsClickEvent.tvGuidePlayMedia(media: media, programIsLive: true, channel: data!.channel.wrappedValue) : nil
        return ButtonProperties(
            icon: .startOver,
            label: NSLocalizedString("Watch from start", comment: "Button to watch some program from the start"),
            action: {
                guard let tabBarController = UIApplication.shared.mainTabBarController else { return }
                if HistoryCanResumePlaybackForMedia(media), HistoryPlaybackProgressForMedia(media) != 0 {
                    let alertController = UIAlertController(title: NSLocalizedString("Watch from start?", comment: "Resume playback alert title"),
                                                            message: NSLocalizedString("You already played this content.", comment: "Resume playback alert explanation"),
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Resume", comment: "Alert choice to resume playback"), style: .default, handler: { _ in
                        analyticsClickEvent?.send()

                        tabBarController.dismissAndPresentMediaPlayer(with: media, position: nil)
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Watch from start", comment: "Alert choice to watch content from start"), style: .default, handler: { _ in
                        analyticsClickEvent?.send()

                        tabBarController.dismissAndPresentMediaPlayer(with: media, position: .default)
                    }))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Title of a cancel button"), style: .cancel, handler: nil))
                    tabBarController.play_top.present(alertController, animated: true, completion: nil)
                } else {
                    analyticsClickEvent?.send()

                    tabBarController.dismissAndPresentMediaPlayer(with: media, position: nil)
                }
            }
        )
    }

    private var watchLaterAllowedAction: WatchLaterAction {
        mediaData.watchLaterAllowedAction
    }

    var watchLaterButtonProperties: ButtonProperties? {
        guard !isLive, let media else { return nil }

        func toggleWatchLater() {
            WatchLaterToggleMedia(media) { added, error in
                guard error == nil else { return }

                let action = added ? .add : .remove as AnalyticsListAction
                AnalyticsEvent.watchLater(action: action, source: .button, urn: media.urn).send()

                self.mediaData = MediaData(media: media, watchLaterAllowedAction: added ? .remove : .add, progress: self.mediaData.progress)
            }
        }

        switch watchLaterAllowedAction {
        case .add:
            switch media.mediaType {
            case .audio:
                return ButtonProperties(
                    icon: .watchLater,
                    label: NSLocalizedString("Listen later", comment: "Button label in program detail view to add an audio to the later list"),
                    action: toggleWatchLater
                )
            default:
                return ButtonProperties(
                    icon: .watchLater,
                    label: NSLocalizedString("Watch later", comment: "Button label in program detail view to add a video to the later list"),
                    action: toggleWatchLater
                )
            }
        case .remove:
            return ButtonProperties(
                icon: .watchLaterFull,
                label: NSLocalizedString("Later", comment: "Watch later or listen later button label in program detail view when a media is in the later list"),
                action: toggleWatchLater
            )
        default:
            return nil
        }
    }

    var calendarButtonProperties: ButtonProperties? {
        ButtonProperties(
            icon: .calendar,
            label: NSLocalizedString("Add to Calendar", comment: "Button to add an event to Calendar application"),
            action: {
                guard let program = self.program,
                      let channel = self.data?.channel,
                      let tabBarController = UIApplication.shared.mainTabBarController else { return }
                let eventStore = EKEventStore()
                eventStore.requestAccessToEvents(completion: { [weak self] granted, error in
                    DispatchQueue.main.async {
                        guard error == nil else {
                            Banner.showError(error as NSError?)
                            return
                        }

                        guard let self else { return }
                        if granted {
                            let event = EKEvent(eventStore: eventStore)
                            event.title = "\(program.title) - \(channel.wrappedValue.title)"
                            event.startDate = program.startDate
                            event.endDate = program.endDate
                            event.url = self.calendarUrl
                            event.notes = self.calendarNotes

                            let eventController = EKEventEditViewController()
                            eventController.event = event
                            eventController.eventStore = eventStore
                            eventController.editViewDelegate = self.eventEditViewDelegateObject
                            tabBarController.play_top.present(eventController, animated: true, completion: nil)
                        } else {
                            let applicationName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
                            let alertController = UIAlertController(title: String(format: NSLocalizedString("“%@” would like to access to your calendar", comment: "Add to Calendar alert title"), applicationName),
                                                                    message: NSLocalizedString("The application uses the calendar to add TV programs.", comment: "Add to Calendar alert explanation"),
                                                                    preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: NSLocalizedString("Open system settings", comment: "Label of the button opening system settings"), style: .default, handler: { _ in
                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                            }))
                            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Title of a cancel button"), style: .cancel, handler: nil))
                            tabBarController.play_top.present(alertController, animated: true, completion: nil)
                        }
                    }
                })
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
                      let window = UIApplication.shared.mainWindow
                else {
                    return
                }
                let pageViewController = PageViewController(id: .show(show))
                tabBarController.pushViewController(pageViewController, animated: false)
                window.play_dismissAllViewControllers(animated: true, completion: nil)
            }
        )
    }

    private var calendarUrl: URL? {
        if let media {
            ApplicationConfiguration.shared.sharingURL(for: media, at: .zero)
        } else if let media = livestreamMedia, program?.timeAvailability(at: Date()) == .notYetAvailable {
            ApplicationConfiguration.shared.sharingURL(for: media, at: .zero)
        } else if let show {
            ApplicationConfiguration.shared.sharingURL(for: show)
        } else {
            ApplicationConfiguration.shared.playURL(for: channel?.vendor ?? ApplicationConfiguration.shared.vendor)
        }
    }

    private var calendarNotes: String? {
        let notes = [calendarShowNote, subtitle, summary]
            .compactMap { $0 }
            .joined(separator: "\n\n")
        return !notes.isEmpty ? notes : nil
    }

    private var calendarShowNote: String? {
        guard let show else { return nil }
        if let url = ApplicationConfiguration.shared.sharingURL(for: show) {
            return "\(show.title)\n\(url)"
        } else {
            return show.title
        }
    }
}

// MARK: Publishers

extension ProgramViewModel {
    private static func mediaDataPublisher(for program: SRGProgram?) -> AnyPublisher<MediaData, Never> {
        if let mediaUrn = program?.mediaURN {
            Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) {
                SRGDataProvider.current!.media(withUrn: mediaUrn)
                    .catch { _ in
                        Empty()
                    }
            }
            .map { media in
                Publishers.CombineLatest(UserDataPublishers.laterAllowedActionPublisher(for: media), UserDataPublishers.playbackProgressPublisher(for: media))
                    .map { action, progress in
                        MediaData(media: media, watchLaterAllowedAction: action, progress: progress)
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .prepend(.empty)
            .eraseToAnyPublisher()
        } else {
            Just(.empty)
                .eraseToAnyPublisher()
        }
    }

    private static func livestreamMediaPublisher(for channel: SRGChannel?) -> AnyPublisher<SRGMedia?, Never> {
        if let channel {
            Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) {
                SRGDataProvider.current!.tvLivestreams(for: channel.vendor)
                    .catch { _ in
                        Empty()
                    }
            }
            .map { $0.first(where: { $0.channel == channel }) }
            .prepend(nil)
            .eraseToAnyPublisher()
        } else {
            Just(nil)
                .eraseToAnyPublisher()
        }
    }
}

// MARK: Types

extension ProgramViewModel {
    /// Data related to the program crew members
    struct CrewMembersData: Identifiable {
        let role: String?
        let names: [String]

        var id: String? {
            role
        }

        init(role: String?, crewMembers: [SRGCrewMember]) {
            self.role = role
            names = crewMembers.map { crewMember in
                if let characterName = crewMember.characterName {
                    "\(crewMember.name) (\(characterName))"
                } else {
                    crewMember.name
                }
            }
        }

        var accessibilityLabel: String {
            "\(role ?? "") \(names.joined(separator: ", "))".trimmingCharacters(in: .whitespaces)
        }
    }

    /// Data related to the media stored by the model
    private struct MediaData {
        let media: SRGMedia?
        let watchLaterAllowedAction: WatchLaterAction
        let progress: Double?

        static var empty = Self(media: nil, watchLaterAllowedAction: .none, progress: nil)
    }

    /// Common button properties
    struct ButtonProperties {
        let icon: ImageResource
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

private extension TabBarController {
    func dismissAndPresentMediaPlayer(with media: SRGMedia, position: SRGPosition?) {
        var presentMediaPlayer: Void { play_presentMediaPlayer(with: media, position: position, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil) }

        if let presentedViewController {
            presentedViewController.dismiss(animated: true) {
                presentMediaPlayer
            }
        } else {
            presentMediaPlayer
        }
    }
}

// MARK: UIKit delegate object

private final class EventEditViewDelegateObject: NSObject, EKEventEditViewDelegate {
    var channel: SRGChannel?

    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true) {
            if action == .saved, let title = controller.event?.title {
                Banner.calendarEventAddedWithTitle(title)

                if let channel = self.channel {
                    AnalyticsEvent.calendarEventAdd(channel: channel).send()
                }
            }
        }
    }
}

// MARK: EKEventStore extension for iOS compatiblity

private extension EKEventStore {
    func requestAccessToEvents(completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
        if #available(iOS 17.0, *) {
            self.requestWriteOnlyAccessToEvents(completion: completion)
        } else {
            requestAccess(to: EKEntityType.event, completion: completion)
        }
    }
}
