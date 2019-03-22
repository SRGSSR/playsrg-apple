//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MainNavigationController.h"
#import "MenuViewController.h"

#import <CoconutKit/CoconutKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Main side menu controller hosting the whole application view controller hierarchy. It comprises a menu which
 *  can either be revealed by tapping on a dedicated button or by swiping from the left edge of the screen, as
 *  well as a center navigation which displays the content associated with the selected menu entry.
 */
@interface SideMenuController : HLSViewController <MainNavigationControllerDelegate, MenuViewControllerDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate>

/**
 *  The currently selected menu item. Same as `-setSelectedMenuItemInfo:animated:` with `animated` set to `NO`. 
 */
@property (nonatomic) MenuItemInfo *selectedMenuItemInfo;

/**
 *  Update the currently selected menu item. The content displayed by the center view is updated accordingly, and the
 *  menu is closed as well.
 */
- (void)setSelectedMenuItemInfo:(MenuItemInfo *)selectedMenuItemInfo animated:(BOOL)animated;

/**
 *  Push the specified view controller into the center navigation controller.
 */
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/**
 *  Display the menu header.
 */
- (void)displayMenuHeaderAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
