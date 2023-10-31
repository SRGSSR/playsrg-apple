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
                
                AnalyticsEvent.continuousPlayback(action: .playAutomatic,
                                                  mediaUrn: media.urn)
                .send()
            }
            .store(in: &cancellables)
    }
}

extension LetterboxDelegate: SRGLetterboxViewControllerDelegate {
    func letterboxViewController(_ letterboxViewController: SRGLetterboxViewController, didEngageInContinuousPlaybackWithUpcomingMedia upcomingMedia: SRGMedia) {
        AnalyticsEvent.continuousPlayback(action: .play,
                                          mediaUrn: upcomingMedia.urn)
        .send()
    }
    
    func letterboxViewController(_ letterboxViewController: SRGLetterboxViewController, didCancelContinuousPlaybackWithUpcomingMedia upcomingMedia: SRGMedia) {
        AnalyticsEvent.continuousPlayback(action: .cancel,
                                          mediaUrn: upcomingMedia.urn)
        .send()
    }
    
    func letterboxViewControllerDidStartPicture(inPicture letterboxViewController: SRGLetterboxViewController) {
        AnalyticsEvent.pictureInPicture(urn: letterboxViewController.controller.fullLengthMedia?.urn).send()
    }
}
