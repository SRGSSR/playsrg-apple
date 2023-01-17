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
        NotificationCenter.default.weakPublisher(for: .SRGLetterboxPlaybackDidContinueAutomatically)
            .sink { notification in
                guard let media = notification.userInfo?[SRGLetterboxMediaKey] as? SRGMedia else { return }

                let controller = notification.object as? SRGLetterboxController,
                    playlist = controller?.playlistDataSource as? Playlist
                AnalyticsHiddenEvents.continuousPlayback(source: AnalyticsSource.automatic,
                                                         type: AnalyticsType.actionPlayMedia,
                                                         mediaUrn: media.urn,
                                                         recommendationUid: playlist?.recommendationUid).send()
            }
            .store(in: &cancellables)
    }
}

extension LetterboxDelegate: SRGLetterboxViewControllerDelegate {
    func letterboxViewController(_ letterboxViewController: SRGLetterboxViewController, didEngageInContinuousPlaybackWithUpcomingMedia upcomingMedia: SRGMedia) {
        let playlist = letterboxViewController.controller.playlistDataSource as? Playlist
        AnalyticsHiddenEvents.continuousPlayback(source: AnalyticsSource.button,
                                                 type: AnalyticsType.actionPlayMedia,
                                                 mediaUrn: upcomingMedia.urn,
                                                 recommendationUid: playlist?.recommendationUid).send()
    }
    
    func letterboxViewController(_ letterboxViewController: SRGLetterboxViewController, didCancelContinuousPlaybackWithUpcomingMedia upcomingMedia: SRGMedia) {
        let playlist = letterboxViewController.controller.playlistDataSource as? Playlist
        AnalyticsHiddenEvents.continuousPlayback(source: AnalyticsSource.button,
                                                 type: AnalyticsType.actionCancel,
                                                 mediaUrn: upcomingMedia.urn,
                                                 recommendationUid: playlist?.recommendationUid).send()
    }
    
    func letterboxViewControllerDidStartPicture(inPicture letterboxViewController: SRGLetterboxViewController) {
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.value = letterboxViewController.controller.fullLengthMedia?.urn
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.pictureInPicture.rawValue, labels: labels)
    }
}
