//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGUserData

extension SRGDataProvider {
    /// Publishes the latest 30 episodes for a show URN list
    func latestMediasForShowsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGMedia], Error> {
        return urns.publisher
            .collect(3)
            .flatMap { urns in
                return self.latestMediasForShows(withUrns: urns, filter: .episodesOnly, pageSize: 15)
            }
            .reduce([]) { $0 + $1 }
            .map { medias in
                return Array(medias.sorted(by: { $0.date > $1.date }).prefix(30))
            }
            .eraseToAnyPublisher()
    }
    
    /// Publishes radio livestreams, replacing regional radio channels. Updates are published down the pipeline as they
    /// are retrieved.
    func regionalizedRadioLivestreams(for vendor: SRGVendor, contentProviders: SRGContentProviders = .default) -> AnyPublisher<[SRGMedia], Error> {
        #if os(iOS)
        return radioLivestreams(for: vendor, contentProviders: contentProviders)
            .flatMap { medias -> AnyPublisher<[SRGMedia], Error> in
                var regionalizedMedias = medias
                return Publishers.MergeMany(regionalizedMedias.compactMap { media -> AnyPublisher<[SRGMedia], Error>? in
                    guard let channelUid = media.channel?.uid else { return nil }
                    
                    // If a regional stream has been selected by the user, replace the main channel media with it
                    let selectedLivestreamUrn = ApplicationSettingSelectedLivestreamURNForChannelUid(channelUid)
                    if selectedLivestreamUrn != nil && media.urn != selectedLivestreamUrn {
                        return self.radioLivestreams(for: vendor, channelUid: channelUid)
                            .map { result in
                                if let selectedMedia = ApplicationSettingSelectedLivestreamMediaForChannelUid(channelUid, medias) {
                                    guard let index = regionalizedMedias.firstIndex(of: media) else { return regionalizedMedias }
                                    regionalizedMedias[index] = selectedMedia
                                }
                                return regionalizedMedias
                            }
                            .eraseToAnyPublisher()
                    }
                    else {
                        return Just(regionalizedMedias)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                })
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        #else
        return radioLivestreams(for: vendor, contentProviders: contentProviders)
            .eraseToAnyPublisher()
        #endif
    }
    
    func historyPublisher() -> AnyPublisher<[SRGMedia], Error> {
        // Drive updates with notifications, using `prepend(_:)` to trigger an initial update
        // Inpsired from https://stackoverflow.com/questions/66075000/swift-combine-publishers-where-one-hasnt-sent-a-value-yet
        NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)
            .map { _ in }
            .prepend(())
            .flatMap { _ in
                return Future<[SRGHistoryEntry], Error> { promise in
                    let sortDescriptor = NSSortDescriptor(keyPath: \SRGHistoryEntry.date, ascending: false)
                    SRGUserData.current!.history.historyEntries(matching: nil, sortedWith: [sortDescriptor]) { historyEntries, error in
                        if let error = error {
                            promise(.failure(error))
                        }
                        else {
                            promise(.success(historyEntries ?? []))
                        }
                    }
                }
            }
            .map { historyEntries in
                historyEntries.compactMap { $0.uid }
            }
            .flatMap { urns in
                return self.medias(withUrns: urns, pageSize: 50 /* Use largest page size */)
            }
            // TODO: Currently suboptimal: For each media we determine if playback can be resumed, an operation on
            //       the main thread and with a single user data access each time. We could  instead use a currrently
            //       private history API to combine the history entries we have and the associated medias we retrieve
            //       with a network request, calculating the progress on a background thread and with only a single
            //       user data access (the one made at the beginning). This optimization seems premature, though, so
            //       for the moment a simpler implementation is used.
            .receive(on: DispatchQueue.main)
            .map { $0.filter { HistoryCanResumePlaybackForMedia($0) } }
            .eraseToAnyPublisher()
    }
    
    func laterPublisher() -> AnyPublisher<[SRGMedia], Error> {
        NotificationCenter.default.publisher(for: Notification.Name.SRGPlaylistEntriesDidChange, object: SRGUserData.current?.playlists)
            .drop { notification in
                if let playlistUid = notification.userInfo?[SRGPlaylistUidKey] as? String, playlistUid == SRGPlaylistUid.watchLater.rawValue {
                    return false
                }
                else {
                    return true
                }
            }
            .map { _ in }
            .prepend(())
            .flatMap { _ in
                return Future<[SRGPlaylistEntry], Error> { promise in
                    let sortDescriptor = NSSortDescriptor(keyPath: \SRGPlaylistEntry.date, ascending: false)
                    SRGUserData.current!.playlists.playlistEntriesInPlaylist(withUid: SRGPlaylistUid.watchLater.rawValue, matching: nil, sortedWith: [sortDescriptor]) { playlistEntries, error in
                        if let error = error {
                            promise(.failure(error))
                        }
                        else {
                            promise(.success(playlistEntries ?? []))
                        }
                    }
                }
            }
            .map { playlistEntries in
                playlistEntries.compactMap { $0.uid }
            }
            .flatMap { urns in
                return self.medias(withUrns: urns, pageSize: 50 /* Use largest page size */)
            }
            .eraseToAnyPublisher()
    }
    
    func showsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGShow], Error> {
        let trigger = Trigger()
        
        return shows(withUrns: urns, pageSize: 50 /* Use largest page size */, triggerId: trigger.id(1))
            .handleEvents(receiveOutput: { shows in
                // FIXME: There is probably a better way
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    trigger.signal(1)
                }
            })
            .reduce([]) { $0 + $1 }
            .map { $0.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending } }
            .eraseToAnyPublisher()
    }
    
    func favoritesPublisher(filter: SectionFiltering) -> AnyPublisher<[SRGShow], Error> {
        return NotificationCenter.default.publisher(for: Notification.Name.SRGPreferencesDidChange, object: SRGUserData.current?.preferences)
            .drop { notification in
                if let domains = notification.userInfo?[SRGPreferencesDomainsKey] as? Set<String>, domains.contains(PlayPreferencesDomain) {
                    return false
                }
                else {
                    return true
                }
            }
            .map { _ in }
            .prepend(())
            .flatMap { _ in
                // For some reason (compiler bug?) the type of the items is seen as [Any]
                return self.showsPublisher(withUrns: FavoritesShowURNs().array as? [String] ?? [])
                    .map { filter.compatibleShows($0) }
            }
            .eraseToAnyPublisher()
    }
}
