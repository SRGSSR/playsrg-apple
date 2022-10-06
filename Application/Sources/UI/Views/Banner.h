//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Supported banner styles.
 */
typedef NS_ENUM(NSInteger, BannerStyle) {
    BannerStyleInfo,
    BannerStyleWarning,
    BannerStyleError
};

/**
 *  Use banners to display messages to the end user.
 */
@interface Banner : NSObject

/**
 *  Show a banner.
 *
 *  @param style   The style to apply.
 *  @param message The message to display.
 *  @param image   Optional leading image.
 *  @param view    The view context for which the banner must be displayed.
 */
+ (void)showWithStyle:(BannerStyle)style message:(nullable NSString *)message image:(nullable UIImage *)image sticky:(BOOL)sticky;

/**
 *  Hide all banners.
 */
+ (void)hideAll;

@end

@interface Banner (Convenience)

/**
 *  Show a banner for the specified error.
 *
 *  @discussion If no error is provided, the method does nothing.
 */
+ (void)showError:(nullable NSError *)error;

/**
 *  Show a banner telling the user that the specified item has been added or removed from favorites.
 *
 *  @discussion If no name is provided, a standard description will be used.
 */
+ (void)showFavorite:(BOOL)isFavorite forItemWithName:(nullable NSString *)name;

/**
 *  Show a banner telling the user that the specified item has been added or removed from downloads.
 *
 *  @discussion If no name is provided, a standard description will be used.
 */
+ (void)showDownload:(BOOL)downloaded forItemWithName:(nullable NSString *)name;

/**
 *  Show a banner telling the user that the specified item has been added to or removed from the subscription list.
 *
 *  @discussion If no name is provided, a standard description will be used.
 */
+ (void)showSubscription:(BOOL)subscribed forItemWithName:(nullable NSString *)name;

/**
 *  Show a banner telling the user that the specified item has been added to or removed from the later list.
 *
 *  @discussion If no name is provided, a standard description will be used.
 */
+ (void)showWatchLaterAdded:(BOOL)added forItemWithName:(nullable NSString *)name;

/**
 *  Show a banner telling the user that the specified event has been added to Calendar.
 *
 *  @discussion If no name is provided, no banner displayed.
 */
+ (void)calendarEventAddedWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
