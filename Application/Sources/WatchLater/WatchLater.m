//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "WatchLater.h"

#import "PlaySRG-Swift.h"

#if TARGET_OS_IOS
#import "DeprecatedFavorite.h"
#endif
#import "NSArray+PlaySRG.h"

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

BOOL WatchLaterContainsMedia(SRGMedia *media)
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGPlaylistEntry.new, uid), media.URN];
    return [SRGUserData.currentUserData.playlists playlistEntriesInPlaylistWithUid:SRGPlaylistUidWatchLater matchingPredicate:predicate sortedWithDescriptors:nil].count > 0;
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
    BOOL contained = WatchLaterContainsMedia(media);
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
}

#if TARGET_OS_IOS

void WatchLaterMigrate(void)
{
    NSCAssert(SRGUserData.currentUserData != nil, @"User data storage must be available");
    
    SRGPlaylist *watchLaterPlaylist = [SRGUserData.currentUserData.playlists playlistWithUid:SRGPlaylistUidWatchLater];
    if (watchLaterPlaylist) {
        NSArray<DeprecatedFavorite *> *favorites = [DeprecatedFavorite mediaFavorites];
        if (favorites.count == 0) {
            return;
        }
        
        // Don't add livestreams to the later list.
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(DeprecatedFavorite.new, mediaContentType), @(FavoriteMediaContentTypeLive)];
        NSArray<DeprecatedFavorite *> *livestreamFavorites = [favorites filteredArrayUsingPredicate:predicate];
        [DeprecatedFavorite finishMigrationForFavorites:livestreamFavorites];
        
        NSArray<DeprecatedFavorite *> *nonLivestreamFavorites = [favorites play_arrayByRemovingObjectsInArray:livestreamFavorites];
        __block NSUInteger remainingFavoritesCount = nonLivestreamFavorites.count;
        
        for (DeprecatedFavorite *favorite in nonLivestreamFavorites) {
            [SRGUserData.currentUserData.playlists savePlaylistEntryWithUid:favorite.mediaURN inPlaylistWithUid:SRGPlaylistUidWatchLater completionBlock:^(NSError * _Nullable error) {
                --remainingFavoritesCount;
                if (remainingFavoritesCount == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [DeprecatedFavorite finishMigrationForFavorites:nonLivestreamFavorites];
                    });
                }
            }];
        }
    }
    else {
        [NSNotificationCenter.defaultCenter addObserverForName:SRGPlaylistsDidChangeNotification object:SRGUserData.currentUserData.playlists queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
            if ([notification.userInfo[SRGPlaylistUidKey] containsObject:SRGPlaylistUidWatchLater]) {
                WatchLaterMigrate();
            }
        }];
    }
}

#endif
