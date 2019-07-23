//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SideMenuController.h"

#import "AnalyticsConstants.h"

#import <HockeySDK/HockeySDK.h>
#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayAppDelegate : UIResponder <BITHockeyManagerDelegate, BITUpdateManagerDelegate, SKStoreProductViewControllerDelegate, UIApplicationDelegate>

@property (nonatomic) UIWindow *window;

@property (nonatomic, readonly) SideMenuController *sideMenuController;

- (BOOL)openMediaWithURN:(NSString *)mediaURN startTime:(NSInteger)startTime channelUid:(nullable NSString *)channelUid fromPushNotification:(BOOL)fromPushNotification completionBlock:(void (^)(void))completionBlock;
- (BOOL)openShowWithURN:(NSString *)showURN channelUid:(nullable NSString *)channelUid fromPushNotification:(BOOL)fromPushNotification completionBlock:(void (^)(void))completionBlock;

/**
 *  Load what's new information, calling the completion handler on completion. The caller is responsible of displaying the
 *  view controller received in case of success.
 */
- (void)loadWhatsNewWithCompletionHandler:(void (^)(UIViewController * _Nullable viewController, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END

