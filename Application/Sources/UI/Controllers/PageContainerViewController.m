//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PageContainerViewController.h"

#import "PlayLogger.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"
#import "UIVisualEffectView+PlaySRG.h"

#import "MaterialTabs.h"
@import SRGAppearance;

@interface PageContainerViewController () <MDCTabBarDelegate>

@property (nonatomic) UIPageViewController *pageViewController;

@property (nonatomic) NSArray<UIViewController *> *viewControllers;
@property (nonatomic) NSUInteger initialPage;

@property (nonatomic, weak) MDCTabBar *tabBar;
@property (nonatomic, weak) UIVisualEffectView *blurView;

@end

@implementation PageContainerViewController

#pragma mark Object lifecycle

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers initialPage:(NSUInteger)initialPage
{
    NSAssert(viewControllers.count != 0, @"At least one view controller is required");
    
    if (self = [super init]) {
        self.viewControllers = viewControllers;
        
        if (initialPage >= viewControllers.count) {
            PlayLogWarning(@"pageViewController", @"Invalid page. Fixed to 0");
            initialPage = 0;
        }
        self.initialPage = initialPage;
        
        UIPageViewController *pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                                   navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                                 options:@{ UIPageViewControllerOptionInterPageSpacingKey : @100.f }];
        pageViewController.delegate = self;
        
        // Only allow scrolling if several pages are available
        if (viewControllers.count > 1) {
            pageViewController.dataSource = self;
        }
        
        self.pageViewController = pageViewController;
        [self addChildViewController:pageViewController];
    }
    return self;
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
{
    return [self initWithViewControllers:viewControllers initialPage:0];
}

#pragma mark View lifecycle

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view.backgroundColor = UIColor.srg_gray16Color;
    
    UIView *pageView = self.pageViewController.view;
    [self.view insertSubview:pageView atIndex:0];
    
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [pageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [pageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [pageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [pageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
    
    [self.pageViewController didMoveToParentViewController:self];
    
    UIVisualEffectView *blurView = UIVisualEffectView.play_blurView;
    [self.view addSubview:blurView];
    self.blurView = blurView;
    
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [blurView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [blurView.heightAnchor constraintEqualToConstant:60.f],
        [blurView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
    
    __block BOOL hasImage = NO;
    
    NSMutableArray<UITabBarItem *> *tabBarItems = [NSMutableArray array];
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
        UITabBarItem *tabBarItem = viewController.tabBarItem;
        if (tabBarItem.image) {
            hasImage = YES;
        }
        [tabBarItems addObject:tabBarItem];
    }];
    
    MDCTabBar *tabBar = [[MDCTabBar alloc] init];
    tabBar.itemAppearance = hasImage ? MDCTabBarItemAppearanceImages : MDCTabBarItemAppearanceTitles;
    tabBar.alignment = MDCTabBarAlignmentCenter;
    tabBar.delegate = self;
    tabBar.items = tabBarItems.copy;
    
    tabBar.tintColor = UIColor.whiteColor;
    tabBar.unselectedItemTintColor = UIColor.srg_gray96Color;
    tabBar.selectedItemTintColor = UIColor.whiteColor;
        
    // Use ripple effect without color, so that there is no Material-like highlighting (we are NOT adopting Material)
    tabBar.enableRippleBehavior = YES;
    tabBar.rippleColor = UIColor.clearColor;
    
    [blurView.contentView addSubview:tabBar];
    self.tabBar = tabBar;
    
    tabBar.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [tabBar.topAnchor constraintEqualToAnchor:blurView.contentView.topAnchor],
        [tabBar.bottomAnchor constraintEqualToAnchor:blurView.contentView.bottomAnchor],
        [tabBar.leadingAnchor constraintEqualToAnchor:blurView.contentView.leadingAnchor],
        [tabBar.trailingAnchor constraintEqualToAnchor:blurView.contentView.trailingAnchor]
    ]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pageContainerViewController_contentSizeCategoryDidChange:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    
    [self updateFonts];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tabBar.selectedItem = self.tabBar.items[self.initialPage];
    
    UIViewController *initialViewController = self.viewControllers[self.initialPage];
    [self.pageViewController setViewControllers:@[initialViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self didDisplayViewController:initialViewController animated:NO];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Force a refresh of the tab bar so that the alignment is correct after rotation
        self.tabBar.alignment = MDCTabBarAlignmentLeading;
        self.tabBar.alignment = MDCTabBarAlignmentCenter;
    } completion:nil];
}

#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [super supportedInterfaceOrientations] & UIViewController.play_supportedInterfaceOrientations;
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Accessibility

- (BOOL)accessibilityPerformEscape
{
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
        return YES;
    }
    else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark Actions

- (BOOL)switchToIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (! [self displayPageAtIndex:index animated:animated]) {
        return NO;
    }
    
    if (self.tabBar) {
        [self.tabBar setSelectedItem:self.tabBar.items[index] animated:animated];
    }
    else {
        self.initialPage = index;
    }
    return YES;
}

#pragma mark Display

- (BOOL)displayPageAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (index >= self.viewControllers.count) {
        return NO;
    }
    
    UIViewController *currentViewController = self.pageViewController.viewControllers.firstObject;
    NSUInteger currentIndex = [self.viewControllers indexOfObject:currentViewController];
    UIPageViewControllerNavigationDirection direction = (currentIndex < index) ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    
    UIViewController *newViewController = self.viewControllers[index];
    [self.pageViewController setViewControllers:@[newViewController] direction:direction animated:animated completion:nil];
    
    [self didDisplayViewController:newViewController animated:animated];
    return YES;
}

#pragma mark UI

- (void)updateFonts
{
    UIFont *tabBarFont = [SRGFont fontWithStyle:SRGFontStyleBody];
    self.tabBar.unselectedItemTitleFont = tabBarFont;
    self.tabBar.selectedItemTitleFont = tabBarFont;
}

#pragma mark Stubs

- (void)didDisplayViewController:(UIViewController *)viewController animated:(BOOL)animated
{}

#pragma mark ContainerContentInsets protocol

- (UIEdgeInsets)play_additionalContentInsets
{
    return UIEdgeInsetsMake(CGRectGetHeight(self.blurView.frame), 0.f, 0.f, 0.f);
}

#pragma mark MDCTabBarDelegate protocol

- (void)tabBar:(MDCTabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    NSUInteger index = [tabBar.items indexOfObject:item];
    [self displayPageAtIndex:index animated:YES];
}

#pragma mark SRGAnalyticsContainerViewTracking protocol

- (NSArray<UIViewController *> *)srg_activeChildViewControllers
{
    return self.pageViewController ? @[self.pageViewController] : @[];
}

#pragma mark TabBarActionable protocol

- (void)performActiveTabActionAnimated:(BOOL)animated
{
    UIViewController *currentViewController = self.pageViewController.viewControllers.firstObject;
    if ([currentViewController conformsToProtocol:@protocol(TabBarActionable)]) {
        UIViewController<TabBarActionable> *actionableCurrentViewController = (UIViewController<TabBarActionable> *)currentViewController;
        [actionableCurrentViewController performActiveTabActionAnimated:animated];
    }
}

#pragma mark UIPageViewControllerDataSource protocol

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger currentIndex = [self.viewControllers indexOfObject:viewController];
    if (currentIndex > 0) {
        return self.viewControllers[currentIndex - 1];
    }
    else {
        return nil;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger currentIndex = [self.viewControllers indexOfObject:viewController];
    if (currentIndex < self.viewControllers.count - 1) {
        return self.viewControllers[currentIndex + 1];
    }
    else {
        return nil;
    }
}

#pragma mark UIPageViewControllerDelegate protocol

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        UIViewController *newViewController = pageViewController.viewControllers.firstObject;
        NSUInteger currentIndex = [self.viewControllers indexOfObject:newViewController];
        [self.tabBar setSelectedItem:self.tabBar.items[currentIndex] animated:YES];;
        [self didDisplayViewController:newViewController animated:YES];
    }
}

#pragma mark Notifications

- (void)pageContainerViewController_contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self updateFonts];
}

@end

@implementation UIViewController (PageContainerViewController)

#pragma mark Getters and setters

- (PageContainerViewController *)play_pageContainerViewController
{
    UIViewController *parentViewController = self.parentViewController.parentViewController;
    if ([parentViewController isKindOfClass:PageContainerViewController.class]) {
        return (PageContainerViewController *)parentViewController;
    }
    else {
        return nil;
    }
}

@end

