//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderModel
import SRGUserData
import SwiftUI

private class MediaContextMenuModel: ObservableObject {
    @Published private(set) var watchLaterAllowedAction: WatchLaterAction = .none
    @Published private(set) var downloaded: Bool = false
    
    private var mainCancellables = Set<AnyCancellable>()
    
    var media: SRGMedia? = nil {
        didSet {
            updateWatchLaterAllowedAction()
            updateDownloaded()
        }
    }
    
    init() {
        NotificationCenter.default.publisher(for: Notification.Name.SRGPlaylistEntriesDidChange, object: SRGUserData.current?.playlists)
            .sink { [weak self] notification in
                guard let self = self,
                      let playlistUid = notification.userInfo?[SRGPlaylistUidKey] as? String, playlistUid == SRGPlaylistUid.watchLater.rawValue,
                      let entriesUids = notification.userInfo?[SRGPlaylistEntriesUidsKey] as? Set<String>, let mediaUrn = self.media?.urn, entriesUids.contains(mediaUrn) else {
                    return
                }
                self.updateWatchLaterAllowedAction()
            }
            .store(in: &mainCancellables)
    }
    
    private func updateWatchLaterAllowedAction() {
        guard let media = media else { return }
        watchLaterAllowedAction = WatchLaterAllowedActionForMediaMetadata(media)
    }
    
    private func updateDownloaded() {
        guard let media = media else { return }
        downloaded = (Download(for: media) != nil)
    }
}

private struct MediaContextMenu<Content: View>: View {
    @Binding var media: SRGMedia?
    @StateObject var model = MediaContextMenuModel()
    
    let content: () -> Content
    
    init(media: SRGMedia?, @ViewBuilder content: @escaping () -> Content) {
        _media = .constant(media)
        self.content = content
    }
    
    var body: some View {
        content()
            // This ensures the extruded view has a correct frame (for some reason to be determined)
            .background(Color.clear)
            .contextMenu {
                WatchLaterMenuItem(model: model)
                DownloadMenuItem(model: model)
            }
            .onAppear {
                model.media = media
            }
            .onChange(of: media) { newValue in
                model.media = newValue
            }
    }
    
    private struct WatchLaterMenuItem: View {
        @ObservedObject var model: MediaContextMenuModel
        
        var body: some View {
            if let media = model.media {
                Button(action: {}) {
                    if model.watchLaterAllowedAction == .add {
                        if media.mediaType == .audio {
                            Label(
                                NSLocalizedString("Listen later", comment: "Context menu action to add an audio to the later list"),
                                image: "watch_later-22"
                            )
                        }
                        else {
                            Label(
                                NSLocalizedString("Watch later", comment: "Context menu action to add a video to the later list"),
                                image: "watch_later-22"
                            )
                        }
                    }
                    else {
                        Label(
                            NSLocalizedString("Delete from \"Later\"", comment: "Context menu action to delete a media from the later list"),
                            image: "watch_later_full-22"
                        )
                    }
                }
            }
        }
    }
    
    private struct DownloadMenuItem: View {
        @ObservedObject var model: MediaContextMenuModel
        
        var body: some View {
            Button(action: {}) {
                if model.media != nil {
                    if model.downloaded {
                        Label(
                            NSLocalizedString("Delete from downloads", comment: "Context menu action to delete a media from the downloads"),
                            image: "downloadable_full-22"
                        )
                    }
                    else {
                        Label(
                            NSLocalizedString("Add to downloads", comment: "Context menu action to add a media to the downloads"),
                            image: "downloadable-22"
                        )
                    }
                }
            }
        }
    }
}

extension View {
    func contextMenu(for media: SRGMedia?) -> some View {
        return MediaContextMenu(media: media) {
            self
        }
    }
}
