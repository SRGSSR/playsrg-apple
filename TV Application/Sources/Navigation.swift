//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGAnalytics
import SRGAppearanceSwift
import TvOSTextViewer
import SwiftUI

var isPresenting = false
var cancellables = Set<AnyCancellable>()

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
        applyLetterboxControllerSettings(to: controller)
        
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
                    labels.extraValue1 = playlist.recommendationUid;
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

func navigateToShow(_ show: SRGShow, animated: Bool = true) {
    guard !isPresenting else { return }
    
    let hostController = UIHostingController(rootView: ShowDetailView(show: show))
    present(hostController, animated: animated)
}

func navigateToTopic(_ topic: SRGTopic, animated: Bool = true) {
    guard !isPresenting else { return }
    
    let hostController = UIHostingController(rootView: TopicView(topic))
    present(hostController, animated: animated)
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

fileprivate func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
    guard let topViewController = UIApplication.shared.keyWindow?.topViewController else { return }
    
    isPresenting = true
    topViewController.present(viewController, animated: animated) {
        isPresenting = false
        if let completion = completion {
            completion()
        }
    }
}

fileprivate func applyLetterboxControllerSettings(to controller: SRGLetterboxController) {
    controller.serviceURL = SRGDataProvider.current?.serviceURL
    controller.globalParameters = SRGDataProvider.current?.globalParameters
    
    let applicationConfiguration = ApplicationConfiguration.shared
    controller.endTolerance = applicationConfiguration.endTolerance;
    controller.endToleranceRatio = applicationConfiguration.endToleranceRatio;
}
