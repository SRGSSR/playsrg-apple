//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsConstants.h"
#import "TabBarController.h"

#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayAppDelegate : UIResponder <SKStoreProductViewControllerDelegate, UIApplicationDelegate>

@property (nonatomic) UIWindow *window;

@property (nonatomic, readonly) TabBarController *rootTabBarController;

- (void)openMediaWithURN:(NSString *)mediaURN startTime:(NSInteger)startTime channelUid:(nullable NSString *)channelUid fromPushNotification:(BOOL)fromPushNotification completionBlock:(void (^)(void))completionBlock;
- (void)openShowWithURN:(NSString *)showURN channelUid:(nullable NSString *)channelUid fromPushNotification:(BOOL)fromPushNotification completionBlock:(void (^)(void))completionBlock;

@end

NS_ASSUME_NONNULL_END

