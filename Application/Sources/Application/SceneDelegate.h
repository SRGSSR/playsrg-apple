//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TabBarController.h"

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (nonatomic, nullable) UIWindow *window;
@property (nonatomic, readonly, nullable) TabBarController *rootTabBarController;

- (void)openMediaWithURN:(NSString *)mediaURN startTime:(NSInteger)startTime channelUid:(nullable NSString *)channelUid fromPushNotification:(BOOL)fromPushNotification sourceUid:(nullable NSString *)sourceUid completionBlock:(void (^)(void))completionBlock;
- (void)openShowWithURN:(NSString *)showURN channelUid:(nullable NSString *)channelUid fromPushNotification:(BOOL)fromPushNotification completionBlock:(void (^)(void))completionBlock;

@end

NS_ASSUME_NONNULL_END
