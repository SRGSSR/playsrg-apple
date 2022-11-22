//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseViewController.h"
#import "Orientation.h"

@import SRGAnalytics;
@import SRGLetterbox;

NS_ASSUME_NONNULL_BEGIN

@interface MediaPlayerViewController : BaseViewController <Oriented, SRGLetterboxViewDelegate, SRGLetterboxPictureInPictureDelegate, SRGAnalyticsViewTracking,
    UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, NSUserActivityDelegate>

// Use nil for starting at the default location (resumes if the media is already being played)
- (instancetype)initWithURN:(NSString *)URN position:(nullable SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification sourceUid:(nullable NSString *)sourceUid;
- (instancetype)initWithMedia:(SRGMedia *)media position:(nullable SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification sourceUid:(nullable NSString *)sourceUid;
- (instancetype)initWithController:(SRGLetterboxController *)controller position:(nullable SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification;

@property (nonatomic, readonly) SRGLetterboxController *letterboxController;

@end

@interface MediaPlayerViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
