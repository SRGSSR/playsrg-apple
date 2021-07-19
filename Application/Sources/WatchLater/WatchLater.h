//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;

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
 *  The action possible for a watch later item.
 */
typedef NS_ENUM(NSInteger, WatchLaterAction) {
    WatchLaterActionNone = 0,
    WatchLaterActionAdd,
    WatchLaterActionRemove
};

/**
 *  Return the allowed watch later action for a given media metadata.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT WatchLaterAction WatchLaterAllowedActionForMediaMetadata(id<SRGMediaMetadata> _Nonnull mediaMetadata);

/**
 *  Return `YES` if the media metadata is in the later list.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT BOOL WatchLaterContainsMediaMetadata(id<SRGMediaMetadata> mediaMetadata);

/**
 *  Add a media metadata to the later list.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void WatchLaterAddMediaMetadata(id<SRGMediaMetadata> mediaMetadata, void (^completion)(NSError * _Nullable error));

/**
 *  Remove a list of media metadata from the later list.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void WatchLaterRemoveMediaMetadataList(NSArray<id<SRGMediaMetadata>> *mediaMetadataList, void (^completion)(NSError * _Nullable error));

/**
 *  Toggle a media metadata in the watch later list.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void WatchLaterToggleMediaMetadata(id<SRGMediaMetadata> mediaMetadata, void (^completion)(BOOL added, NSError * _Nullable error));

/**
 *  Migrate favorites (legacy plist-based way of bookmarking medias), if any, to the later playlist.
 */
OBJC_EXPORT void WatchLaterMigrate(void) API_UNAVAILABLE(tvos);

NS_ASSUME_NONNULL_END
