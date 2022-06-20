//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAnalytics
import SRGAppearanceSwift
#if os(tvOS)
import TvOSTextViewer
#endif
import SRGDataProviderModel
import SwiftUI
import UIKit

// FIXME: We should attempt to merge both iOS and tvOS navigations

#if os(iOS)

extension UIViewController {
    func navigateToItem(_ item: Content.Item) {
        switch item {
        case let .media(media):
            play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
        case let .show(show):
            if let navigationController = navigationController {
                let showViewController = SectionViewController.showViewController(for: show)
                navigationController.pushViewController(showViewController, animated: true)
            }
        case let .topic(topic):
            if let navigationController = navigationController {
                let pageViewController = PageViewController(id: .topic(topic))
                navigationController.pushViewController(pageViewController, animated: true)
            }
        case let .download(download):
            if let media = download.media {
                play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
            }
            else {
                let error = NSError(
                    domain: PlayErrorDomain,
                    code: PlayErrorCode.notFound.rawValue,
                    userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString("Media not available yet", comment: "Message on top screen when trying to open a media in the download list and the media is not downloaded.")
                    ]
                )
                Banner.showError(error)
            }
        case let .notification(notification):
            navigateToNotification(notification)
        default:
            break
        }
    }
    
    @objc func navigateToNotification(_ notification: UserNotification) {
        UserNotification.saveNotification(notification, read: true)
        
        if let mediaUrn = notification.mediaURN {
            SRGDataProvider.current!.media(withURN: mediaUrn) { media, _, error in
                if let media = media {
                    self.play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true) { _ in
                        let labels = SRGAnalyticsHiddenEventLabels()
                        labels.source = notification.showURN ?? AnalyticsSource.notification.rawValue
                        labels.type = UserNotificationTypeString(notification.type) ?? AnalyticsType.actionPlayMedia.rawValue
                        labels.value = mediaUrn
                        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.notificationOpen.rawValue, labels: labels)
                    }
                }
                else if let error = error {
                    Banner.showError(error)
                }
            }
            .resume()
        }
        else if let showUrn = notification.showURN {
            SRGDataProvider.current!.show(withURN: showUrn) { show, _, error in
                if let show = show {
                    let showViewController = SectionViewController.showViewController(for: show)
                    self.navigationController?.pushViewController(showViewController, animated: true)
                    
                    let labels = SRGAnalyticsHiddenEventLabels()
                    labels.source = AnalyticsSource.notification.rawValue
                    labels.type = UserNotificationTypeString(notification.type) ?? AnalyticsType.actionDisplayShow.rawValue
                    labels.value = showUrn
                    SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.notificationOpen.rawValue, labels: labels)
                }
                else if let error = error {
                    Banner.showError(error)
                }
            }
            .resume()
        }
        else {
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.source = AnalyticsSource.notification.rawValue
            labels.type = UserNotificationTypeString(notification.type) ?? AnalyticsType.actionNotificationAlert.rawValue
            labels.value = notification.body
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.notificationOpen.rawValue, labels: labels)
        }
    }
}

#else

private var isPresenting = false

private var mediaCancellable: AnyCancellable?
private var cancellables = Set<AnyCancellable>()

func navigateToMedia(_ media: SRGMedia, play: Bool = false, animated: Bool = true) {
    guard !isPresenting else { return }
    
    if !play && media.contentType != .livestream {
        let hostController = UIHostingController(rootView: MediaDetailView(media: media))
        present(hostController, animated: animated)
    }
    else {
        let letterboxViewController = SRGLetterboxViewController()
        letterboxViewController.delegate = LetterboxDelegate.shared
        
        let controller = letterboxViewController.controller
        let playlist = PlaylistForURN(media.urn)
        controller.playlistDataSource = playlist
        controller.playbackTransitionDelegate = playlist
        ApplicationConfigurationApplyControllerSettings(controller)
        
        controller.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil) { _ in
            HistoryUpdateLetterboxPlaybackProgress(controller)
        }
        
        controller.publisher(for: \.continuousPlaybackUpcomingMedia)
            .sink { upcomingMedia in
                guard let upcomingMedia = upcomingMedia else { return }
                
                let labels = SRGAnalyticsHiddenEventLabels()
                labels.source = AnalyticsSource.automatic.rawValue
                labels.type = AnalyticsType.actionDisplay.rawValue
                labels.value = upcomingMedia.urn
                
                if let playlist = controller.playlistDataSource as? Playlist {
                    labels.extraValue1 = playlist.recommendationUid
                }
                SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.continuousPlayback.rawValue, labels: labels)
            }
            .store(in: &cancellables)
        
        let position = HistoryResumePlaybackPositionForMedia(media)
        controller.playMedia(media, at: position, withPreferredSettings: nil)
        present(letterboxViewController, animated: animated) {
            SRGAnalyticsTracker.shared.trackPageView(withTitle: AnalyticsPageTitle.player.rawValue, levels: [AnalyticsPageLevel.play.rawValue])
        }
    }
}

func navigateToProgram(_ program: SRGProgram, in channel: SRGChannel, animated: Bool = true) {
    mediaCancellable = mediaPublisher(for: program, in: channel)?
        .receive(on: DispatchQueue.main)
        .sink { _ in
        } receiveValue: { media in
            navigateToMedia(media, animated: animated)
        }
}

func navigateToShow(_ show: SRGShow, animated: Bool = true) {
    guard !isPresenting else { return }
    
    let showViewController = SectionViewController(section: .configured(.show(show)))
    present(showViewController, animated: animated)
}

func navigateToTopic(_ topic: SRGTopic, animated: Bool = true) {
    guard !isPresenting else { return }
    
    let pageViewController = PageViewController(id: .topic(topic))
    present(pageViewController, animated: animated)
}

func navigateToSection(_ section: Content.Section, filter: SectionFiltering?, animated: Bool = true) {
    guard !isPresenting else { return }
    
    let sectionViewController = SectionViewController(section: section, filter: filter)
    present(sectionViewController, animated: animated)
}

func showText(_ text: String, animated: Bool = true) {
    guard !isPresenting else { return }
    
    let textViewController = TvOSTextViewerViewController()
    textViewController.text = text
    textViewController.textAttributes = [
        .foregroundColor: UIColor.white,
        .font: SRGFont.font(.body) as UIFont
    ]
    textViewController.textEdgeInsets = UIEdgeInsets(top: 100, left: 250, bottom: 100, right: 250)
    textViewController.modalPresentationStyle = .overFullScreen
    present(textViewController, animated: animated)
}

private func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
    guard let topViewController = UIApplication.shared.mainTopViewController else { return }
    
    isPresenting = true
    topViewController.present(viewController, animated: animated) {
        isPresenting = false
        if let completion = completion {
            completion()
        }
    }
}

private func mediaPublisher(for program: SRGProgram, in channel: SRGChannel) -> AnyPublisher<SRGMedia, Error>? {
    if program.play_contains(Date()) {
        return SRGDataProvider.current!.tvLivestreams(for: channel.vendor)
            .compactMap { $0.first(where: { $0.channel == channel }) }
            .eraseToAnyPublisher()
    }
    else if let mediaUrn = program.mediaURN {
        return SRGDataProvider.current!.media(withUrn: mediaUrn)
    }
    else {
        return nil
    }
}

#endif
