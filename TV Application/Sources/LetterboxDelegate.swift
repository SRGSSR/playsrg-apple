//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import Combine

class LetterboxDelegate: NSObject {
    static let shared = LetterboxDelegate()
    
    var cancellables = Set<AnyCancellable>()

    override init() {
        NotificationCenter.default.publisher(for: .SRGLetterboxPlaybackDidContinueAutomatically)
            .sink { notification in
                guard let media = notification.userInfo?[SRGLetterboxMediaKey] as? SRGMedia else { return }

                let labels = SRGAnalyticsHiddenEventLabels()
                labels.source = AnalyticsSource.automatic.rawValue
                labels.type = AnalyticsType.actionPlayMedia.rawValue
                labels.value = media.urn
                
                if let controller = notification.object as? SRGLetterboxController, let playlist = controller.playlistDataSource as? Playlist {
                    labels.extraValue1 = playlist.recommendationUid
                }
                SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.continuousPlayback.rawValue, labels: labels)
            }
            .store(in: &cancellables)
    }
}

extension LetterboxDelegate: SRGLetterboxViewControllerDelegate {
    func letterboxViewController(_ letterboxViewController: SRGLetterboxViewController, didEngageInContinuousPlaybackWithUpcomingMedia upcomingMedia: SRGMedia) {
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.source = AnalyticsSource.button.rawValue
        labels.type = AnalyticsType.actionPlayMedia.rawValue
        labels.value = upcomingMedia.urn
        
        if let playlist = letterboxViewController.controller.playlistDataSource as? Playlist {
            labels.extraValue1 = playlist.recommendationUid
        }
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.continuousPlayback.rawValue, labels: labels)
    }
    
    func letterboxViewController(_ letterboxViewController: SRGLetterboxViewController, didCancelContinuousPlaybackWithUpcomingMedia upcomingMedia: SRGMedia) {
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.source = AnalyticsSource.button.rawValue
        labels.type = AnalyticsType.actionCancel.rawValue
        labels.value = upcomingMedia.urn
        
        if let playlist = letterboxViewController.controller.playlistDataSource as? Playlist {
            labels.extraValue1 = playlist.recommendationUid
        }
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.continuousPlayback.rawValue, labels: labels)
    }
    
    func letterboxViewControllerDidStartPicture(inPicture letterboxViewController: SRGLetterboxViewController) {
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.value = letterboxViewController.controller.fullLengthMedia?.urn
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.pictureInPicture.rawValue, labels: labels)
    }
}
