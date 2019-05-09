//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "WatchLater.h"

#import "Favorite+Private.h"

#import <libextobjc/libextobjc.h>
#import <SRGUserData/SRGUserData.h>

NSString * const WatchLaterDidChangeNotification = @"WatchLaterDidChangeNotification";
NSString * const WatchLaterMediaMetadataUidKey = @"WatchLaterMediaMetadataUid";
NSString * const WatchLaterMediaMetadataStateKey = @"WatchLaterMediaMetadataStateKey";

#pragma mark Media metadata functions

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

void WatchLaterMigrate(void)
{
    NSCAssert(SRGUserData.currentUserData != nil, @"User data storage must be available");
    
    SRGPlaylist *watchLaterPlaylist = [SRGUserData.currentUserData.playlists playlistWithUid:SRGPlaylistUidWatchLater];
    if (watchLaterPlaylist) {
        NSArray<Favorite *> *favorites = [Favorite mediaFavorites];
        
        __block NSUInteger remainingFavoritesCount = favorites.count;
        if (remainingFavoritesCount == 0) {
            return;
        }
        
        for (Favorite *favorite in favorites) {
            [SRGUserData.currentUserData.playlists savePlaylistEntryWithUid:favorite.mediaURN inPlaylistWithUid:SRGPlaylistUidWatchLater completionBlock:^(NSError * _Nullable error) {
                --remainingFavoritesCount;
                if (remainingFavoritesCount == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [Favorite finishMigrationForFavorites:favorites];
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
