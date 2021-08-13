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
typedef NS_ENUM(NSInteger, WatchLaterState) {
    /**
     *  Added media metadata.
     */
    WatchLaterStateAdded = 0,
    /**
     *  Removed media metadata.
     */
    WatchLaterStateRemoved
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
 *  Return the allowed watch later action for a given media.
 *
 *  @discussion The non-async variant must be called on the main thread. The async variant block can be called from
 *              any thread.
 */
OBJC_EXPORT WatchLaterAction WatchLaterAllowedActionForMedia(SRGMedia * _Nonnull media);
OBJC_EXPORT NSString *WatchLaterAllowedActionForMediaAsync(SRGMedia * _Nonnull media, void (^completion)(WatchLaterAction action));

/**
 *  Return `YES` if the media is in the later list.
 *
 *  @discussion The non-async variant must be called on the main thread. The async variant block can be called from
 *              any thread.
 */
OBJC_EXPORT BOOL WatchLaterContainsMedia(SRGMedia *media);
OBJC_EXPORT NSString *WatchLaterContainsMediaAsync(SRGMedia *media, void (^completion)(BOOL contained));

/**
 *  Add a media to the later list.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void WatchLaterAddMedia(SRGMedia *media, void (^completion)(NSError * _Nullable error));

/**
 *  Remove a list of medias from the later list.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void WatchLaterRemoveMedias(NSArray<SRGMedia *> *medias, void (^completion)(NSError * _Nullable error));

/**
 *  Toggle a media in the watch later list.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void WatchLaterToggleMedia(SRGMedia *medias, void (^completion)(BOOL added, NSError * _Nullable error));

/**
 *  Cancel a progress async request.
 */
OBJC_EXPORT void WatchLaterAsyncCancel(NSString * _Nullable handle);

/**
 *  Migrate favorites (legacy plist-based way of bookmarking medias), if any, to the later playlist.
 */
OBJC_EXPORT void WatchLaterMigrate(void) API_UNAVAILABLE(tvos);

NS_ASSUME_NONNULL_END
