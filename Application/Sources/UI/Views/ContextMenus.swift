//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

extension View {
    func contextMenu(for media: SRGMedia?) -> some View {
        return Group {
            if let media = media {
                self
                    // Ensure correct frame for some reason
                    .background(Color.clear)
                    .contextMenu {
                        if let action = WatchLaterAllowedActionForMediaMetadata(media), action != .none {
                            Button(action: {}) {
                                Self.labelForWatchLater(with: media, action: action)
                            }
                        }
                        if Download.canDownloadMedia(media) {
                            Button(action: {}) {
                                Self.labelForDownload(with: media)
                            }
                        }
                        Button(action: {}) {
                            Label(
                                NSLocalizedString("Share", comment: "Context menu action to share a media"),
                                image: "share-22"
                            )
                        }
                        if !ApplicationConfiguration.shared.areShowsUnavailable && media.show != nil {
                            Button(action: {}) {
                                Label(
                                    NSLocalizedString("More episodes", comment: "Context menu action to open more episodes associated with a media"),
                                    image: "episodes-22"
                                )
                            }
                        }
                        Button(action: {}) {
                            Text("Open")
                        }
                    }
            }
            else {
                self
            }
        }
    }
    
    private static func labelForWatchLater(with media: SRGMedia, action: WatchLaterAction) -> some View {
        if action == .add {
            if media.mediaType == .audio {
                return Label(
                    NSLocalizedString("Listen later", comment: "Context menu action to add an audio to the later list"),
                    image: "watch_later-22"
                )
            }
            else {
                return Label(
                    NSLocalizedString("Watch later", comment: "Context menu action to add a video to the later list"),
                    image: "watch_later-22"
                )
            }
        }
        else {
            return Label(
                NSLocalizedString("Delete from \"Later\"", comment: "Context menu action to delete a media from the later list"),
                image: "watch_later_full-22"
            )
        }
    }
    
    private static func labelForDownload(with media: SRGMedia) -> some View {
        if Download(for: media) != nil {
            return Label(
                NSLocalizedString("Delete from downloads", comment: "Context menu action to delete a media from the downloads"),
                image: "downloadable_full-22"
            )
        }
        else {
            return Label(
                NSLocalizedString("Add to downloads", comment: "Context menu action to add a media to the downloads"),
                image: "downloadable-22"
            )
        }
    }
}
