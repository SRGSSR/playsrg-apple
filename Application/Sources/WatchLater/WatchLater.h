//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  WatchLater media metadata state.
 */
typedef NS_ENUM(NSInteger, WatchLaterMediaMetadataState) {
    /**
     *  Added media metadata.
     */
    WatchLaterMediaMetadataStateAdded = 0,
    /**
     *  Removed media metadata.
     */
    WatchLaterMediaMetadataStateRemoved
};

/**
 *  Notification sent when one media metadata changes. Use the keys below to retrieve detailed information from the notification
 *  `userInfo` dictionary.
 *
 *  @discussion These notifications are broadcasted without any object and received on the main thread.
 */
OBJC_EXPORT NSString * const WatchLaterDidChangeNotification;                     // Notification name.

OBJC_EXPORT NSString * const WatchLaterMediaMetadataUidKey;                       // Key to access the media metata uid (`NSString`) which have changed.
OBJC_EXPORT NSString * const WatchLaterMediaMetadataStateKey;                     // Key to access the new uid media metata state as an `NSNumber` (wrapping an `WatchLaterMediaMetadataState` value).

/**
 *  Return `YES` if the media metadata can be added to the watch later list.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT BOOL WatchLaterCanStoreMediaMetadata(id<SRGMediaMetadata> _Nonnull mediaMetadata);

/**
 *  Return `YES` if the media metadata is in the watch later list.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT BOOL WatchLaterContainsMediaMetadata(id<SRGMediaMetadata> _Nonnull mediaMetadata);

/**
 *  Add a media metadata to the watch later list.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void WatchLaterAddMediaMetadata(id<SRGMediaMetadata> _Nonnull mediaMetadata, void (^completion)(NSError * _Nullable error));

/**
 *  Remove a media metadata to the watch later list.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void WatchLaterRemoveMediaMetadata(id<SRGMediaMetadata> _Nonnull mediaMetadata, void (^completion)(NSError * _Nullable error));

/**
 *  Toggle a media metadata to the watch later list.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void WatchLaterToggleMediaMetadata(id<SRGMediaMetadata> _Nonnull mediaMetadata, void (^completion)(BOOL added, NSError * _Nullable error));

/**
 *  Migrate favorites (legacy plist-based way of bookmarking medias), if any to the watch later playlist.
 */
OBJC_EXPORT void WatchLaterMigrate(void);

NS_ASSUME_NONNULL_END
