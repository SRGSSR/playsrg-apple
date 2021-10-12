//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "WatchLater.h"

#import "PlaySRG-Swift.h"

@import libextobjc;
@import SRGUserData;

WatchLaterAction WatchLaterAllowedActionForMedia(SRGMedia *media)
{    
    if (WatchLaterContainsMedia(media)) {
        return WatchLaterActionRemove;
    }
    else if (media.contentType != SRGContentTypeLivestream && [media timeAvailabilityAtDate:NSDate.date] != SRGTimeAvailabilityNotAvailableAnymore) {
        return WatchLaterActionAdd;
    }
    else {
        return WatchLaterActionNone;
    }
}

NSString *WatchLaterAllowedActionForMediaAsync(SRGMedia * _Nonnull media, void (^completion)(WatchLaterAction action))
{
    return WatchLaterContainsMediaAsync(media, ^(BOOL contained) {
        if (contained) {
            completion(WatchLaterActionRemove);
        }
        else if (media.contentType != SRGContentTypeLivestream && [media timeAvailabilityAtDate:NSDate.date] != SRGTimeAvailabilityNotAvailableAnymore) {
            completion(WatchLaterActionAdd);
        }
        else {
            completion(WatchLaterActionNone);
        }
    });
}

BOOL WatchLaterContainsMedia(SRGMedia *media)
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGPlaylistEntry.new, uid), media.URN];
    return [SRGUserData.currentUserData.playlists playlistEntriesInPlaylistWithUid:SRGPlaylistUidWatchLater matchingPredicate:predicate sortedWithDescriptors:nil].count > 0;
}

NSString *WatchLaterContainsMediaAsync(SRGMedia *media, void (^completion)(BOOL contained))
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGPlaylistEntry.new, uid), media.URN];
    return [SRGUserData.currentUserData.playlists playlistEntriesInPlaylistWithUid:SRGPlaylistUidWatchLater matchingPredicate:predicate sortedWithDescriptors:nil completionBlock:^(NSArray<SRGPlaylistEntry *> * _Nullable playlistEntries, NSError * _Nullable error) {
        completion(playlistEntries.count > 0);
    }];
}

void WatchLaterAddMedia(SRGMedia *media, void (^completion)(NSError * _Nullable error))
{
    [SRGUserData.currentUserData.playlists savePlaylistEntryWithUid:media.URN inPlaylistWithUid:SRGPlaylistUidWatchLater completionBlock:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (! error) {
                [UserInteractionEvent addToWatchLater:@[media]];
            }
            completion(error);
        });
    }];
}

void WatchLaterRemoveMedias(NSArray<SRGMedia *> *medias, void (^completion)(NSError * _Nullable error))
{
    NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(SRGMedia.new, URN)];
    NSArray<NSString *> *URNs = [medias valueForKeyPath:keyPath];
    [SRGUserData.currentUserData.playlists discardPlaylistEntriesWithUids:URNs fromPlaylistWithUid:SRGPlaylistUidWatchLater completionBlock:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (! error) {
                [UserInteractionEvent removeFromWatchLater:medias];
            }
            completion(error);
        });
    }];
}

void WatchLaterToggleMedia(SRGMedia *media, void (^completion)(BOOL added, NSError * _Nullable error))
{
    WatchLaterContainsMediaAsync(media, ^(BOOL contained) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (contained) {
                WatchLaterRemoveMedias(@[media], ^(NSError * _Nullable error) {
                    completion(NO, error);
                });
            }
            else {
                WatchLaterAddMedia(media, ^(NSError * _Nullable error) {
                    completion(YES, error);
                });
            }
        });
    });
}

void WatchLaterAsyncCancel(NSString *handle)
{
    if (handle) {
        [SRGUserData.currentUserData.playlists cancelTaskWithHandle:handle];
    }
}
