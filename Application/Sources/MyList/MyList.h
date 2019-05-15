//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return `YES` if the show is in My List.
 *
 *  @discussion Must be called from the main thread,
 */
OBJC_EXPORT BOOL MyListContainsShow(SRGShow * _Nonnull show);

/**
 *  Add a show to My List.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT void MyListAddShow(SRGShow * _Nonnull show);

/**
 *  Remove mshows from My List. If `nil`, all shows are removed.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT void MyListRemoveShows(NSArray<SRGShow *> * _Nullable shows);

/**
 *  Toggle a show to My List. Return `YES` if the show is in My List after.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT BOOL MyListToggleShow(SRGShow * _Nonnull show);

/**
 *  Get all show URNs in My List.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT NSSet<NSString *> * MyListShowURNs();

/**
 *  Migrate favorites (legacy plist-based way of bookmarking shows) and subscriptions, if any to My List.
 */
OBJC_EXPORT void MyListMigrate(void);

NS_ASSUME_NONNULL_END
