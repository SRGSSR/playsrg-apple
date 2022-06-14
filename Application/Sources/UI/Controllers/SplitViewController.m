//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SplitViewController.h"

@implementation SplitViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.delegate = self;
    }
    return self;
}

#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIInterfaceOrientationMask supportedInterfaceOrientations = [super supportedInterfaceOrientations];
    for (UIViewController *viewController in self.viewControllers) {
        supportedInterfaceOrientations &= viewController.supportedInterfaceOrientations;
    }
    return supportedInterfaceOrientations;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    for (UIViewController *viewController in self.viewControllers) {
        UIUserInterfaceSizeClass horizontalSizeClass = CGRectGetWidth(viewController.view.frame) < 600.f ? UIUserInterfaceSizeClassCompact : UIUserInterfaceSizeClassRegular;
        UITraitCollection *horizontalTraitCollection = [UITraitCollection traitCollectionWithHorizontalSizeClass:horizontalSizeClass];
        UITraitCollection *verticalTraitCollection = [UITraitCollection traitCollectionWithVerticalSizeClass:self.traitCollection.verticalSizeClass];
        UITraitCollection *traitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:@[horizontalTraitCollection, verticalTraitCollection]];
        [self setOverrideTraitCollection:traitCollection forChildViewController:viewController];
    }
}

#pragma mark Status bar

- (BOOL)prefersStatusBarHidden
{
    return [self.viewControllers.firstObject prefersStatusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.viewControllers.firstObject preferredStatusBarStyle];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.viewControllers.firstObject preferredStatusBarUpdateAnimation];
}

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    UIViewController *primaryViewController = self.viewControllers.firstObject;
    if ([primaryViewController conformsToProtocol:@protocol(PlayApplicationNavigation)]) {
        UIViewController<PlayApplicationNavigation> *navigablePrimaryViewController = (UIViewController<PlayApplicationNavigation> *)primaryViewController;
        return [navigablePrimaryViewController openApplicationSectionInfo:applicationSectionInfo];
    }
    else {
        return NO;
    }
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UIViewController *lastViewController = self.viewControllers.lastObject;
    if ([lastViewController isKindOfClass:UINavigationController.class]) {
        UINavigationController *navigationTopViewController = (UINavigationController *)lastViewController;
        [navigationTopViewController pushViewController:viewController animated:animated];
    }
}

#pragma mark ScrollableContentContainer protocol

- (UIViewController *)play_scrollableChildViewController
{
    return self.viewControllers.lastObject;
}

#pragma mark TabBarActionable protocol

- (void)performActiveTabActionAnimated:(BOOL)animated
{
    void (^performActiveTabAction)(UIViewController *) = ^(UIViewController *viewController) {
        if ([viewController conformsToProtocol:@protocol(TabBarActionable)]) {
            UIViewController<TabBarActionable> *actionableViewController = (UIViewController<TabBarActionable> *)viewController;
            [actionableViewController performActiveTabActionAnimated:animated];
        }
    };
    
    UIViewController *lastViewController = self.viewControllers.lastObject;
    performActiveTabAction(lastViewController);
}

#pragma mark UISplitViewControllerDelegate protocol

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showViewController:(UIViewController *)vc sender:(id)sender
{
    [self play_setNeedsScrollableViewUpdate];
    return NO;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showDetailViewController:(UIViewController *)vc sender:(id)sender
{
    [self play_setNeedsScrollableViewUpdate];
    return NO;
}

- (void)splitViewControllerDidExpand:(UISplitViewController *)svc
{
    [self play_setNeedsScrollableViewUpdate];
}

- (void)splitViewControllerDidCollapse:(UISplitViewController *)svc
{
    [self play_setNeedsScrollableViewUpdate];
}

@end
