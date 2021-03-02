//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

class LetterboxDelegate: NSObject, SRGLetterboxViewControllerDelegate {
    static let shared = LetterboxDelegate()
    
    // MARK: - SRGLetterboxViewControllerDelegate protocol

    func letterboxViewController(_ letterboxViewController: SRGLetterboxViewController, didEngageInContinuousPlaybackWithUpcomingMedia upcomingMedia: SRGMedia) {
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.source = AnalyticsSource.button.rawValue
        labels.type = AnalyticsType.actionPlayMedia.rawValue
        labels.value = upcomingMedia.urn
        
        if letterboxViewController.controller.playlistDataSource is Playlist {
            let playlist = letterboxViewController.controller.playlistDataSource as! Playlist
            labels.extraValue1 = playlist.recommendationUid;
        }
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.continuousPlayback.rawValue, labels: labels)
    }
    
    func letterboxViewController(_ letterboxViewController: SRGLetterboxViewController, didCancelContinuousPlaybackWithUpcomingMedia upcomingMedia: SRGMedia) {
        let labels = SRGAnalyticsHiddenEventLabels()
        labels.source = AnalyticsSource.button.rawValue
        labels.type = AnalyticsType.actionCancel.rawValue
        labels.value = upcomingMedia.urn
        
        if letterboxViewController.controller.playlistDataSource is Playlist {
            let playlist = letterboxViewController.controller.playlistDataSource as! Playlist
            labels.extraValue1 = playlist.recommendationUid;
        }
        SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.continuousPlayback.rawValue, labels: labels)
    }
}
