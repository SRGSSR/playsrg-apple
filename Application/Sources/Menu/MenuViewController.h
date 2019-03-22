//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoconutKit/CoconutKit.h>
#import "MenuSectionInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class MenuViewController;

@protocol MenuViewControllerDelegate <NSObject>

// Only called interactively
- (void)menuViewController:(MenuViewController *)menuViewController didSelectMenuItemInfo:(MenuItemInfo *)menuItemInfo;

@end

@interface MenuViewController : HLSViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) MenuItemInfo *selectedMenuItemInfo;
@property (nonatomic, weak, nullable) id<MenuViewControllerDelegate> delegate;

// Put the focus onto the menu
- (void)focus;

- (void)scrollToTopAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
