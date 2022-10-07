//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSectionInfo.h"
#import "ContentInsets.h"
#import "Orientation.h"
#import "PlayApplicationNavigation.h"
#import "ScrollableContent.h"

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface TabBarController : UITabBarController <ContainerContentInsets, Oriented, PlayApplicationNavigation, ScrollableContentContainer, UITabBarControllerDelegate>

/**
 *  Open the application section.
 */
- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo;

/**
 *  Push the specified view controller into the currently selected view controller.
 */
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
