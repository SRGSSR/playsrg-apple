//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalytics
import TvOSTextViewer
import SwiftUI

func navigateToMedia(_ media: SRGMedia, play: Bool = false, animated: Bool = true) {
    guard let topViewController = UIApplication.shared.keyWindow?.topViewController else { return }
    
    if !play && media.contentType != .livestream {
        let hostController = UIHostingController(rootView: MediaDetailView(media: media))
        topViewController.present(hostController, animated: animated, completion: nil)
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
        topViewController.present(letterboxViewController, animated: animated, completion: nil)
        SRGAnalyticsTracker.shared.trackPageView(withTitle: AnalyticsPageTitle.player.rawValue, levels: [AnalyticsPageLevel.play.rawValue])
    }
}

func navigateToShow(_ show: SRGShow, animated: Bool = true) {
    guard let topViewController = UIApplication.shared.keyWindow?.topViewController else { return }
    
    let hostController = UIHostingController(rootView: ShowDetailView(show: show))
    topViewController.present(hostController, animated: animated, completion: nil)
}

func navigateToTopic(_ topic: SRGTopic, animated: Bool = true) {
    guard let topViewController = UIApplication.shared.keyWindow?.topViewController else { return }
    
    let hostController = UIHostingController(rootView: TopicDetailView(topic: topic))
    topViewController.present(hostController, animated: animated, completion: nil)
}

func showText(_ text: String, animated: Bool = true) {
    guard let topViewController = UIApplication.shared.keyWindow?.topViewController else { return }
    
    let textViewController = TvOSTextViewerViewController()
    textViewController.text = text
    textViewController.textAttributes = [
        .foregroundColor: UIColor.white,
        .font: SRGFont.uiFont(.body)
    ]
    textViewController.textEdgeInsets = UIEdgeInsets(top: 100, left: 250, bottom: 100, right: 250)
    textViewController.modalPresentationStyle = .overFullScreen
    topViewController.present(textViewController, animated: animated)
}

fileprivate func applyLetterboxControllerSettings(to controller: SRGLetterboxController) {
    controller.serviceURL = SRGDataProvider.current?.serviceURL
    controller.globalParameters = SRGDataProvider.current?.globalParameters
    
    let applicationConfiguration = ApplicationConfiguration.shared
    controller.endTolerance = applicationConfiguration.endTolerance;
    controller.endToleranceRatio = applicationConfiguration.endToleranceRatio;
}
