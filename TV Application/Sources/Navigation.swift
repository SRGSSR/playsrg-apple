//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalytics
import TvOSTextViewer
import SwiftUI

var isPresenting: Bool = false

func navigateToMedia(_ media: SRGMedia, play: Bool = false, animated: Bool = true) {
    if !play && media.contentType != .livestream {
        let hostController = UIHostingController(rootView: MediaDetailView(media: media))
        present(hostController, animated: animated)
    }
    else {
        let letterboxViewController = SRGLetterboxViewController()
        
        let controller = letterboxViewController.controller
        let playlist = PlaylistForURN(media.urn)
        controller.playlistDataSource = playlist
        controller.playbackTransitionDelegate = playlist
        applyLetterboxControllerSettings(to: controller)
        
        controller.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil) { _ in
            HistoryUpdateLetterboxPlaybackProgress(controller)
        }

        let position = HistoryResumePlaybackPositionForMedia(media)
        controller.playMedia(media, at: position, withPreferredSettings: nil)
        present(letterboxViewController, animated: animated) {
            SRGAnalyticsTracker.shared.trackPageView(withTitle: AnalyticsPageTitle.player.rawValue, levels: [AnalyticsPageLevel.play.rawValue])
        }
    }
}

func navigateToShow(_ show: SRGShow, animated: Bool = true) {
    let hostController = UIHostingController(rootView: ShowDetailView(show: show))
    present(hostController, animated: animated)
}

func navigateToTopic(_ topic: SRGTopic, animated: Bool = true) {
    let hostController = UIHostingController(rootView: TopicDetailView(topic: topic))
    present(hostController, animated: animated)
}

func showText(_ text: String, animated: Bool = true) {
    let textViewController = TvOSTextViewerViewController()
    textViewController.text = text
    textViewController.textAttributes = [
        .foregroundColor: UIColor.white,
        .font: SRGFont.uiFont(.body)
    ]
    textViewController.textEdgeInsets = UIEdgeInsets(top: 100, left: 250, bottom: 100, right: 250)
    textViewController.modalPresentationStyle = .overFullScreen
    present(textViewController, animated: animated)
}

func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
    guard !isPresenting, let topViewController = UIApplication.shared.keyWindow?.topViewController else { return }
    
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
