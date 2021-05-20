//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Play domain for `SRGPreferences`.
 */
OBJC_EXPORT NSString * const PlayPreferencesDomain;


/**
 *  @name Favorite entries
 */

/**
 *  Return `YES` if the show is in favorites.
 */
OBJC_EXPORT BOOL FavoritesContainsShow(SRGShow * _Nonnull show);

/**
 *  Add a show to favorites.
 */
OBJC_EXPORT void FavoritesAddShow(SRGShow * _Nonnull show);

/**
 *  Remove shows from favorites. If `nil`, all shows are removed.
 */
OBJC_EXPORT void FavoritesRemoveShows(NSArray<SRGShow *> * _Nullable shows);

/**
 *  Toggle a show in favorites.
 */
OBJC_EXPORT void FavoritesToggleShow(SRGShow * _Nonnull show);

/**
 *  Get all favorited show URNs.
 */
OBJC_EXPORT NSOrderedSet<NSString *> * _Nonnull FavoritesShowURNs(void);


/**
 *  @name Subscriptions
 */

#if TARGET_OS_IOS

/**
 *  Toggle a subscription for a favorited show.
 *
 *  @discussion The optional view gives the opportunity to display an alert if push notifications are disabled.
 */
OBJC_EXPORT BOOL FavoritesToggleSubscriptionForShow(SRGShow * _Nonnull show, UIView * _Nullable view);

#endif

/**
 *  Return `YES` iff the user has subscribed to the specified show.
 */
OBJC_EXPORT BOOL FavoritesIsSubscribedToShow(SRGShow * _Nonnull show);

#if TARGET_OS_IOS

/**
 *  @name Setup
 */

/**
 *  Setup Favorites to synchronize subscribed shows at any time.
 *
 *  @discussion Needs to be called after the Push Service setup.
 */
OBJC_EXPORT void FavoritesSetup(void);
    

/**
 *  @name Migration
 */

/**
 *  Migrate depretaced favorites (legacy plist-based way of bookmarking shows) and subscriptions, if any to Favorites.
 */
OBJC_EXPORT void FavoritesMigrate(void);

#endif

NS_ASSUME_NONNULL_END
