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
                AnalyticsHiddenEvent.continuousPlayback(action: .playAutomatic,
                                                        mediaUrn: media.urn,
                                                        recommendationUid: playlist?.recommendationUid)
                .send()
            }
            .store(in: &cancellables)
    }
}

extension LetterboxDelegate: SRGLetterboxViewControllerDelegate {
    func letterboxViewController(_ letterboxViewController: SRGLetterboxViewController, didEngageInContinuousPlaybackWithUpcomingMedia upcomingMedia: SRGMedia) {
        let playlist = letterboxViewController.controller.playlistDataSource as? Playlist
        AnalyticsHiddenEvent.continuousPlayback(action: .play,
                                                mediaUrn: upcomingMedia.urn,
                                                recommendationUid: playlist?.recommendationUid)
        .send()
    }
    
    func letterboxViewController(_ letterboxViewController: SRGLetterboxViewController, didCancelContinuousPlaybackWithUpcomingMedia upcomingMedia: SRGMedia) {
        let playlist = letterboxViewController.controller.playlistDataSource as? Playlist
        AnalyticsHiddenEvent.continuousPlayback(action: .cancel,
                                                mediaUrn: upcomingMedia.urn,
                                                recommendationUid: playlist?.recommendationUid)
        .send()
    }
    
    func letterboxViewControllerDidStartPicture(inPicture letterboxViewController: SRGLetterboxViewController) {
        AnalyticsHiddenEvent.pictureInPicture(urn: letterboxViewController.controller.fullLengthMedia?.urn).send()
    }
}
