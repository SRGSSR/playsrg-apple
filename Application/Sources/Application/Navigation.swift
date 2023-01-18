//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAnalytics
import SRGAppearanceSwift
import SRGDataProviderModel
import SwiftUI
#if os(tvOS)
import TvOSTextViewer
#endif
import UIKit

private var cancellable: AnyCancellable?

#if os(tvOS)
private var isPresenting = false
private var cancellables = Set<AnyCancellable>()

extension UIViewController {
    func navigateToMedia(_ media: SRGMedia, play: Bool = false, mediaAnalyticsClickEvent: AnalyticsClickEvent? = nil, playAnalyticsClickEvent: AnalyticsClickEvent? = nil, from program: SRGProgram? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        if !play && media.contentType != .livestream {
            mediaAnalyticsClickEvent?.send()
            
            let hostController = UIHostingController(rootView: MediaDetailView(media: media, playAnalyticsClickEvent: playAnalyticsClickEvent))
            present(hostController, animated: animated, completion: completion)
        }
        else {
            playAnalyticsClickEvent?.send()
            
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
                    guard let upcomingMedia else { return }
                    
                    let playlist = controller.playlistDataSource as? Playlist
                    AnalyticsHiddenEvent.continuousPlayback(source: AnalyticsSource.automatic,
                                                            type: AnalyticsType.actionDisplay,
                                                            mediaUrn: upcomingMedia.urn,
                                                            recommendationUid: playlist?.recommendationUid)
                    .send()
                }
                .store(in: &cancellables)
            
            let position = HistoryResumePlaybackPositionForMedia(media)
            controller.playMedia(media, at: position, withPreferredSettings: nil)
            present(letterboxViewController, animated: animated) {
                SRGAnalyticsTracker.shared.trackPageView(withTitle: AnalyticsPageTitle.player.rawValue, levels: [AnalyticsPageLevel.play.rawValue])
                if let completion {
                    completion()
                }
            }
        }
    }
    
    func navigateToShow(_ show: SRGShow, animated: Bool = true, completion: (() -> Void)? = nil) {
        let showViewController = SectionViewController(section: .configured(.show(show)))
        present(showViewController, animated: animated, completion: completion)
    }
    
    func navigateToTopic(_ topic: SRGTopic, animated: Bool = true, completion: (() -> Void)? = nil) {
        let pageViewController = PageViewController(id: .topic(topic))
        present(pageViewController, animated: animated, completion: completion)
    }
    
    func navigateToProgram(_ program: SRGProgram, in channel: SRGChannel, animated: Bool = true, completion: (() -> Void)? = nil) {
        cancellable = mediaPublisher(for: program, in: channel)?
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // No error banners displayed on tvOS yet
            } receiveValue: { [weak self] media in
                let playAnalyticsClickEvent = media.contentType == .livestream ?
                AnalyticsClickEvent.TvGuidePlayLivestream(program: program, channel: channel) :
                AnalyticsClickEvent.TvGuidePlayMedia(media: media, programIsLive: (program.startDate...program.endDate).contains(Date()), channel: channel)
                let mediaAnalyticsClickEvent = AnalyticsClickEvent.tvGuideOpenInfoBox(program: program, programGuideLayout: .grid)
                
                self?.navigateToMedia(media, mediaAnalyticsClickEvent: mediaAnalyticsClickEvent, playAnalyticsClickEvent: playAnalyticsClickEvent, from: program, animated: animated, completion: completion)
            }
    }
    
    func navigateToSection(_ section: Content.Section, filter: SectionFiltering?, animated: Bool = true, completion: (() -> Void)? = nil) {
        let sectionViewController = SectionViewController(section: section, filter: filter)
        present(sectionViewController, animated: animated, completion: completion)
    }
    
    func navigateToText(_ text: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        let textViewController = TvOSTextViewerViewController()
        textViewController.text = text
        textViewController.textAttributes = [
            .foregroundColor: UIColor.white,
            .font: SRGFont.font(.body) as UIFont
        ]
        textViewController.textEdgeInsets = UIEdgeInsets(top: 100, left: 250, bottom: 100, right: 250)
        textViewController.modalPresentationStyle = .overFullScreen
        present(textViewController, animated: animated, completion: completion)
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
}

func navigateToMedia(_ media: SRGMedia, play: Bool = false, mediaAnalyticsClickEvent: AnalyticsClickEvent? = nil, playAnalyticsClickEvent: AnalyticsClickEvent? = nil, animated: Bool = true) {
    guard !isPresenting, let topViewController = UIApplication.shared.mainTopViewController else { return }
    isPresenting = true
    topViewController.navigateToMedia(media, play: play, mediaAnalyticsClickEvent: mediaAnalyticsClickEvent, playAnalyticsClickEvent: playAnalyticsClickEvent, animated: animated) {
        isPresenting = false
    }
}

func navigateToShow(_ show: SRGShow, animated: Bool = true) {
    guard !isPresenting, let topViewController = UIApplication.shared.mainTopViewController else { return }
    isPresenting = true
    topViewController.navigateToShow(show, animated: animated) {
        isPresenting = false
    }
}

func navigateToSection(_ section: Content.Section, filter: SectionFiltering?, animated: Bool = true) {
    guard !isPresenting, let topViewController = UIApplication.shared.mainTopViewController else { return }
    isPresenting = true
    topViewController.navigateToSection(section, filter: filter, animated: animated) {
        isPresenting = false
    }
}

func navigateToTopic(_ topic: SRGTopic, animated: Bool = true) {
    guard !isPresenting, let topViewController = UIApplication.shared.mainTopViewController else { return }
    isPresenting = true
    topViewController.navigateToTopic(topic, animated: animated) {
        isPresenting = false
    }
}

func navigateToText(_ text: String, animated: Bool = true) {
    guard !isPresenting, let topViewController = UIApplication.shared.mainTopViewController else { return }
    isPresenting = true
    topViewController.navigateToText(text, animated: animated) {
        isPresenting = false
    }
}

#endif

#if os(iOS)
extension UIViewController {
    @objc func navigateToNotification(_ notification: UserNotification, animated: Bool = true) {
        UserNotification.saveNotification(notification, read: true)
        
        if let mediaUrn = notification.mediaURN {
            cancellable = SRGDataProvider.current!.media(withUrn: mediaUrn)
                .receive(on: DispatchQueue.main)
                .sink { result in
                    if case let .failure(error) = result {
                        Banner.showError(error)
                    }
                } receiveValue: { [weak self] media in
                    guard let self else { return }
                    self.play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: animated) { _ in
                        let labels = SRGAnalyticsHiddenEventLabels()
                        labels.source = notification.showURN ?? AnalyticsSource.notification.rawValue
                        labels.type = UserNotificationTypeString(notification.type) ?? AnalyticsType.actionPlayMedia.rawValue
                        labels.value = mediaUrn
                        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.notificationOpen.rawValue, labels: labels)
                    }
                }
        }
        else if let showUrn = notification.showURN {
            cancellable = SRGDataProvider.current!.show(withUrn: showUrn)
                .receive(on: DispatchQueue.main)
                .sink { result in
                    if case let .failure(error) = result {
                        Banner.showError(error)
                    }
                } receiveValue: { [weak self] show in
                    guard let navigationController = self?.navigationController else { return }
                    let showViewController = SectionViewController.showViewController(for: show)
                    navigationController.pushViewController(showViewController, animated: animated)
                    
                    let labels = SRGAnalyticsHiddenEventLabels()
                    labels.source = AnalyticsSource.notification.rawValue
                    labels.type = UserNotificationTypeString(notification.type) ?? AnalyticsType.actionDisplayShow.rawValue
                    labels.value = showUrn
                    SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.notificationOpen.rawValue, labels: labels)
                }
        }
        else {
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.source = AnalyticsSource.notification.rawValue
            labels.type = UserNotificationTypeString(notification.type) ?? AnalyticsType.actionNotificationAlert.rawValue
            labels.value = notification.body
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.notificationOpen.rawValue, labels: labels)
        }
    }
    
    func navigateToDownload(_ download: Download, animated: Bool = true) {
        if let media = download.media {
            play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: animated, completion: nil)
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
    }
    
    func navigateToItem(_ item: Content.Item, animated: Bool = true) {
        switch item {
        case let .media(media):
            play_presentMediaPlayer(with: media, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: animated, completion: nil)
        case let .show(show):
            guard let navigationController else { return }
            let showViewController = SectionViewController.showViewController(for: show)
            navigationController.pushViewController(showViewController, animated: animated)
        case let .topic(topic):
            guard let navigationController else { return }
            let pageViewController = PageViewController(id: .topic(topic))
            navigationController.pushViewController(pageViewController, animated: animated)
        case let .download(download):
            navigateToDownload(download, animated: animated)
        case let .notification(notification):
            navigateToNotification(notification, animated: animated)
        default:
            break
        }
    }
}
#endif
