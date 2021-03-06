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
                    labels.extraValue1 = playlist.recommendationUid
                }
                SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.continuousPlayback.rawValue, labels: labels)
            }
            .store(in: &cancellables)
        
        let position = HistoryResumePlaybackPositionForMediaMetadata(media)
        controller.playMedia(media, at: position, withPreferredSettings: nil)
        present(letterboxViewController, animated: animated) {
            SRGAnalyticsTracker.shared.trackPageView(withTitle: AnalyticsPageTitle.player.rawValue, levels: [AnalyticsPageLevel.play.rawValue])
        }
    }
}

func navigateToShow(_ show: SRGShow, animated: Bool = true) {
    guard !isPresenting else { return }
    
    let showViewController = SectionViewController(section: .configured(.show(show)))
    present(showViewController, animated: animated)
}

func navigateToTopic(_ topic: SRGTopic, animated: Bool = true) {
    guard !isPresenting else { return }
    
    let pageViewController = PageViewController(id: .topic(topic: topic))
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
    guard let topViewController = UIApplication.shared.delegate?.window??.topViewController else { return }
    
    isPresenting = true
    topViewController.present(viewController, animated: animated) {
        isPresenting = false
        if let completion = completion {
            completion()
        }
    }
}

private func applyLetterboxControllerSettings(to controller: SRGLetterboxController) {
    controller.serviceURL = SRGDataProvider.current?.serviceURL
    controller.globalParameters = SRGDataProvider.current?.globalParameters
    
    let applicationConfiguration = ApplicationConfiguration.shared
    controller.endTolerance = applicationConfiguration.endTolerance
    controller.endToleranceRatio = applicationConfiguration.endToleranceRatio
}
