//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Collections
import Combine
import SRGDataProviderCombine
import SRGUserData

extension NotificationCenter {
    /// The usual notification publisher retains the filter object, potentially creating cycles. Apply filter on
    /// unfiltered stream to avoid this issue.
    func weakPublisher(for name: Notification.Name, object: AnyObject? = nil) -> AnyPublisher<Notification, Never> {
        publisher(for: name)
            .filter { [weak object] notification in
                guard let object = object else { return true }
                guard let notificationObject = notification.object as? AnyObject else { return false }
                return notificationObject === object
            }
            .eraseToAnyPublisher()
    }
}

extension SRGDataProvider {
    /// Publishes the latest 30 episodes for a show URN list.
    func latestMediasForShowsPublisher(withUrns urns: [String], pageSize: UInt = SRGDataProviderDefaultPageSize) -> AnyPublisher<[SRGMedia], Error> {
        return urns.publisher
            .collect(3)
            .flatMap { urns in
                return self.latestMediasForShows(withUrns: urns, filter: .episodesOnly, pageSize: 15)
            }
            .reduce([]) { $0 + $1 }
            .map { medias in
                return Array(medias.sorted(by: { $0.date > $1.date }).prefix(Int(pageSize)))
            }
            .eraseToAnyPublisher()
    }
    
#if os(iOS)
    /// Publishes the regional media which corresponds to the specified media, if any.
    private func regionalizedRadioLivestreamMedia(for media: SRGMedia) -> AnyPublisher<SRGMedia, Never> {
        if let channelUid = media.channel?.uid,
           let selectedLivestreamUrn = ApplicationSettingSelectedLivestreamURNForChannelUid(channelUid),
           media.urn != selectedLivestreamUrn {
            return self.radioLivestreams(for: media.vendor, channelUid: channelUid)
                .map { medias in
                    if let selectedMedia = ApplicationSettingSelectedLivestreamMediaForChannelUid(channelUid, medias) {
                        return selectedMedia
                    }
                    else {
                        return media
                    }
                }
                .replaceError(with: media)
                .eraseToAnyPublisher()
        }
        else {
            return Just(media)
                .eraseToAnyPublisher()
        }
    }
#endif
    
    /// Publishes radio livestreams, replacing regional radio channels. Updates are published down the pipeline as they
    /// are retrieved.
    func regionalizedRadioLivestreams(for vendor: SRGVendor, contentProviders: SRGContentProviders = .default) -> AnyPublisher<[SRGMedia], Error> {
#if os(iOS)
        return radioLivestreams(for: vendor, contentProviders: contentProviders)
            .map { medias in
                return Publishers.AccumulateLatestMany(medias.map { media in
                    return self.regionalizedRadioLivestreamMedia(for: media)
                })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
#else
        return radioLivestreams(for: vendor, contentProviders: contentProviders)
            .eraseToAnyPublisher()
#endif
    }
    
    func historyEntriesPublisher() -> AnyPublisher<[String], Error> {
        // Use a deferred future to make it repeatable on-demand
        // See https://heckj.github.io/swiftui-notes/#reference-future
        return Deferred {
            Future<[String], Error> { promise in
                let sortDescriptor = NSSortDescriptor(keyPath: \SRGHistoryEntry.date, ascending: false)
                SRGUserData.current!.history.historyEntries(matching: nil, sortedWith: [sortDescriptor]) { historyEntries, error in
                    if let error = error {
                        promise(.failure(error))
                    }
                    else {
                        promise(.success(historyEntries?.compactMap(\.uid) ?? []))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func historyPublisher(pageSize: UInt = SRGDataProviderDefaultPageSize, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[SRGMedia], Error> {
        return historyEntriesPublisher()
            .map { urns in
                return self.medias(withUrns: urns, pageSize: pageSize, paginatedBy: paginator)
                    .map { filter?.compatibleMedias($0) ?? $0 }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    func resumePlaybackPublisher(pageSize: UInt = SRGDataProviderDefaultPageSize, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[SRGMedia], Error> {
        func playbackPositions(for historyEntries: [SRGHistoryEntry]?) -> OrderedDictionary<String, TimeInterval> {
            guard let historyEntries = historyEntries else { return [:] }
            
            var playbackPositions = OrderedDictionary<String, TimeInterval>()
            for historyEntry in historyEntries {
                if let uid = historyEntry.uid {
                    playbackPositions[uid] = CMTimeGetSeconds(historyEntry.lastPlaybackTime)
                }
            }
            return playbackPositions
        }
        
        // Use a deferred future to make it repeatable on-demand
        // See https://heckj.github.io/swiftui-notes/#reference-future
        return Deferred {
            Future<OrderedDictionary<String, TimeInterval>, Error> { promise in
                let sortDescriptor = NSSortDescriptor(keyPath: \SRGHistoryEntry.date, ascending: false)
                SRGUserData.current!.history.historyEntries(matching: nil, sortedWith: [sortDescriptor]) { historyEntries, error in
                    if let error = error {
                        promise(.failure(error))
                    }
                    else {
                        promise(.success(playbackPositions(for: historyEntries)))
                    }
                }
            }
        }
        .map { playbackPositions in
            return self.medias(withUrns: Array(playbackPositions.keys), pageSize: pageSize, paginatedBy: paginator)
                .map { filter?.compatibleMedias($0) ?? $0 }
                .map {
                    return $0.filter { media in
                        guard let playbackPosition = playbackPositions[media.urn] else { return true }
                        return HistoryCanResumePlaybackForMediaAndPosition(playbackPosition, media)
                    }
                }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
    
    func laterEntriesPublisher() -> AnyPublisher<[String], Error> {
        // Use a deferred future to make it repeatable on-demand
        // See https://heckj.github.io/swiftui-notes/#reference-future
        return Deferred {
            Future<[String], Error> { promise in
                let sortDescriptor = NSSortDescriptor(keyPath: \SRGPlaylistEntry.date, ascending: false)
                SRGUserData.current!.playlists.playlistEntriesInPlaylist(withUid: SRGPlaylistUid.watchLater.rawValue, matching: nil, sortedWith: [sortDescriptor]) { playlistEntries, error in
                    if let error = error {
                        promise(.failure(error))
                    }
                    else {
                        promise(.success(playlistEntries?.compactMap(\.uid) ?? []))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func laterPublisher(pageSize: UInt = SRGDataProviderDefaultPageSize, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[SRGMedia], Error> {
        return laterEntriesPublisher()
            .map { urns in
                return self.medias(withUrns: urns, pageSize: pageSize, paginatedBy: paginator)
                    .map { filter?.compatibleMedias($0) ?? $0 }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    func showsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGShow], Error> {
        let trigger = Trigger()
        
        return shows(withUrns: urns, pageSize: 50 /* Use largest page size */, paginatedBy: trigger.signal(activatedBy: 1))
            .handleEvents(receiveOutput: { _ in
                // FIXME: There is probably a better way
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    trigger.activate(for: 1)
                }
            })
            .reduce([]) { $0 + $1 }
            .map { $0.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending } }
            .eraseToAnyPublisher()
    }
    
    func favoritesPublisher(filter: SectionFiltering?) -> AnyPublisher<[SRGShow], Error> {
        return self.showsPublisher(withUrns: FavoritesShowURNs().array as? [String] ?? [])
            .map { filter?.compatibleShows($0) ?? $0 }
            .eraseToAnyPublisher()
    }
}

enum UserDataPublishers {
    enum SubscriptionStatus {
        case unavailable
        case unsubscribed
        case subscribed
    }
    
    static func playbackProgressPublisher(for media: SRGMedia) -> AnyPublisher<Double?, Never> {
        return Publishers.PublishAndRepeat(onOutputFrom: ThrottledSignal.historyUpdates(for: media.urn)) {
            return Deferred {
                Future<Double?, Never> { promise in
                    HistoryPlaybackProgressForMediaAsync(media) { progress, completed in
                        guard completed else { return }
                        let progressValue = (progress != 0) ? Optional(Double(progress)) : nil
                        promise(.success(progressValue))
                    }
                }
            }
        }
        .prepend(nil)
        .eraseToAnyPublisher()
    }
    
    static func favoritePublisher(for show: SRGShow) -> AnyPublisher<Bool, Never> {
        return ThrottledSignal.preferenceUpdates(interval: 0)
            .prepend(())
            .map { _ in
                return FavoritesContainsShow(show)
            }
            .eraseToAnyPublisher()
    }
    
    static func laterAllowedActionPublisher(for media: SRGMedia) -> AnyPublisher<WatchLaterAction, Never> {
        return Publishers.PublishAndRepeat(onOutputFrom: ThrottledSignal.watchLaterUpdates(for: media.urn)) {
            return Deferred {
                Future<WatchLaterAction, Never> { promise in
                    WatchLaterAllowedActionForMediaAsync(media) { action in
                        promise(.success(action))
                    }
                }
            }
        }
        .prepend(.none)
        .eraseToAnyPublisher()
    }
    
#if os(iOS)
    static func subscriptionStatusPublisher(for show: SRGShow) -> AnyPublisher<SubscriptionStatus, Never> {
        return Publishers.Merge(
            ThrottledSignal.preferenceUpdates(interval: 0),
            ApplicationSignal.pushServiceStatusUpdate()
        )
        .prepend(())
        .map {
            guard let isEnabled = PushService.shared?.isEnabled, isEnabled else { return .unavailable }
            return FavoritesIsSubscribedToShow(show) ? .subscribed : .unsubscribed
        }
        .eraseToAnyPublisher()
    }
#endif
}

#if DEBUG
extension Publisher {
    /**
     *  Dump values passing through the pipeline.
     *
     *  Borrowed from https://peterfriese.dev/posts/swiftui-combine-custom-operators/
     */
    func dump() -> AnyPublisher<Output, Failure> {
        handleEvents { output in
            Swift.dump(output)
        } receiveCompletion: { completion in
            if case let .failure(error) = completion {
                Swift.dump(error)
            }
        }
        .eraseToAnyPublisher()
    }
}
#endif
