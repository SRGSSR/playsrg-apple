//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "WatchLater.h"

#if TARGET_OS_IOS
#import "DeprecatedFavorite.h"
#endif
#import "NSArray+PlaySRG.h"

@import libextobjc;
@import SRGUserData;

NSString * const WatchLaterDidChangeNotification = @"WatchLaterDidChangeNotification";
NSString * const WatchLaterMediaMetadataUidKey = @"WatchLaterMediaMetadataUid";
NSString * const WatchLaterMediaMetadataStateKey = @"WatchLaterMediaMetadataState";

#pragma mark Media metadata functions

WatchLaterAction WatchLaterAllowedActionForMediaMetadata(id<SRGMediaMetadata> mediaMetadata)
{    
    if (WatchLaterContainsMediaMetadata(mediaMetadata)) {
        return WatchLaterActionRemove;
    }
    else if (mediaMetadata.contentType != SRGContentTypeLivestream && [mediaMetadata timeAvailabilityAtDate:NSDate.date] != SRGTimeAvailabilityNotAvailableAnymore) {
        return WatchLaterActionAdd;
    }
    else {
        return WatchLaterActionNone;
    }
}

BOOL WatchLaterContainsMediaMetadata(id<SRGMediaMetadata> mediaMetadata)
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGPlaylistEntry.new, uid), mediaMetadata.URN];
    return [SRGUserData.currentUserData.playlists playlistEntriesInPlaylistWithUid:SRGPlaylistUidWatchLater matchingPredicate:predicate sortedWithDescriptors:nil].count > 0;
}

void WatchLaterAddMediaMetadata(id<SRGMediaMetadata> mediaMetadata, void (^completion)(NSError * _Nullable error))
{
    [SRGUserData.currentUserData.playlists savePlaylistEntryWithUid:mediaMetadata.URN inPlaylistWithUid:SRGPlaylistUidWatchLater completionBlock:^(NSError * _Nullable error) {
         dispatch_async(dispatch_get_main_queue(), ^{
             if (! error) {
                 [NSNotificationCenter.defaultCenter postNotificationName:WatchLaterDidChangeNotification
                                                                   object:nil
                                                                 userInfo:@{ WatchLaterMediaMetadataUidKey : mediaMetadata.URN,
                                                                             WatchLaterMediaMetadataStateKey : @(WatchLaterMediaMetadataStateAdded) }];
             }
             completion(error);
         });
    }];
}

void WatchLaterRemoveMediaMetadata(id<SRGMediaMetadata> mediaMetadata, void (^completion)(NSError * _Nullable error))
{
    [SRGUserData.currentUserData.playlists discardPlaylistEntriesWithUids:@[mediaMetadata.URN] fromPlaylistWithUid:SRGPlaylistUidWatchLater completionBlock:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (! error) {
                [NSNotificationCenter.defaultCenter postNotificationName:WatchLaterDidChangeNotification
                                                                  object:nil
                                                                userInfo:@{ WatchLaterMediaMetadataUidKey : mediaMetadata.URN,
                                                                            WatchLaterMediaMetadataStateKey : @(WatchLaterMediaMetadataStateRemoved) }];
            }
            completion(error);
        });
    }];
}

void WatchLaterToggleMediaMetadata(id<SRGMediaMetadata> _Nonnull mediaMetadata, void (^completion)(BOOL added, NSError * _Nullable error))
{
    BOOL contained = WatchLaterContainsMediaMetadata(mediaMetadata);
    if (contained) {
        WatchLaterRemoveMediaMetadata(mediaMetadata, ^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        });
    }
    else {
        WatchLaterAddMediaMetadata(mediaMetadata, ^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, error);
            });
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
