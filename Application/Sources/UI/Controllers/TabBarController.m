//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TabBarController.h"

#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "Layout.h"
#import "MiniPlayerView.h"
#import "NavigationController.h"
#import "PlaySRG-Swift.h"
#import "ProfileViewController.h"
#import "PushService.h"
#import "SplitViewController.h"
#import "TabBarActionable.h"

@import libextobjc;
@import MAKVONotificationCenter;
@import SRGAppearance;

static const CGFloat MiniPlayerHeight = 50.f;
static const CGFloat MiniPlayerDefaultOffset = 5.f;

@interface TabBarController ()

@property (nonatomic, weak) MiniPlayerView *miniPlayerView;
@property (nonatomic, readonly) CGFloat miniPlayerOffset;

@property (nonatomic, readonly) NSLayoutConstraint *playerWidthConstraint;
@property (nonatomic, readonly) NSLayoutConstraint *playerLeadingConstraint;
@property (nonatomic, readonly) NSLayoutConstraint *playerTrailingConstraint;
@property (nonatomic, readonly) NSLayoutConstraint *playerHeightConstraint;
@property (nonatomic, readonly) NSLayoutConstraint *playerBottomToViewConstraint;
@property (nonatomic, readonly) NSLayoutConstraint *playerBottomToSafeAreaConstraint;

@end

@implementation TabBarController

@synthesize playerWidthConstraint = _playerWidthConstraint;
@synthesize playerLeadingConstraint = _playerLeadingConstraint;
@synthesize playerTrailingConstraint = _playerTrailingConstraint;
@synthesize playerHeightConstraint = _playerHeightConstraint;
@synthesize playerBottomToViewConstraint = _playerBottomToViewConstraint;
@synthesize playerBottomToSafeAreaConstraint = _playerBottomToSafeAreaConstraint;

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.delegate = self;
        
        NSMutableArray<UIViewController *> *viewControllers = NSMutableArray.array;
        
        UIViewController *videosTabViewController = [self videosTabViewController];
        [viewControllers addObject:videosTabViewController];
        
        UIViewController *audiosTabViewController = [self audiosTabViewController];
        if (audiosTabViewController) {
            [viewControllers addObject:audiosTabViewController];
        }
        
        UIViewController *livestreamsTabViewController = [self livestreamsTabViewController];
        if (livestreamsTabViewController) {
            [viewControllers addObject:livestreamsTabViewController];
        }
        
        UIViewController *searchTabViewController = [self searchTabViewController];
        [viewControllers addObject:searchTabViewController];
        
        UIViewController *profileTabViewController = [self profileTabViewController];
        [viewControllers addObject:profileTabViewController];
        
        self.viewControllers = viewControllers.copy;
        
        TabBarItemIdentifier lastOpenTabBarItem = ApplicationSettingLastOpenedTabBarItemIdentifier();
        if (lastOpenTabBarItem) {
            self.selectedIndex = lastOpenTabBarItem;
        }
        
        [self customizeAppearance];
    }
    return self;
}

#pragma mark Getters and setters

- (CGFloat)miniPlayerOffset
{
    return UIAccessibilityIsVoiceOverRunning() ? 0.f : MiniPlayerDefaultOffset;
}

- (NSLayoutConstraint *)playerWidthConstraint
{
    if (! _playerWidthConstraint) {
        _playerWidthConstraint = [self.miniPlayerView.widthAnchor constraintEqualToConstant:0.f];
    }
    return _playerWidthConstraint;
}

- (NSLayoutConstraint *)playerLeadingConstraint
{
    if (! _playerLeadingConstraint) {
        _playerLeadingConstraint = [self.miniPlayerView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor];
    }
    return _playerLeadingConstraint;
}

- (NSLayoutConstraint *)playerTrailingConstraint
{
    if (! _playerTrailingConstraint) {
        _playerTrailingConstraint = [self.miniPlayerView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor];
    }
    return _playerTrailingConstraint;
}

- (NSLayoutConstraint *)playerHeightConstraint
{
    if (! _playerHeightConstraint) {
        _playerHeightConstraint = [self.miniPlayerView.heightAnchor constraintEqualToConstant:0.f];
    }
    return _playerHeightConstraint;
}

- (NSLayoutConstraint *)playerBottomToViewConstraint
{
    NSLayoutConstraint* (^preiOS18ConstraintBlock)() = ^NSLayoutConstraint*() {
        if (! self->_playerBottomToViewConstraint) {
            self->_playerBottomToViewConstraint = [self.miniPlayerView.bottomAnchor constraintEqualToAnchor:self.tabBar.topAnchor];
        }
        return self->_playerBottomToViewConstraint;
    };

    if (@available(iOS 18.0, *)) {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            if (! _playerBottomToViewConstraint) {
                _playerBottomToViewConstraint = [self.miniPlayerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];
            }
            _playerBottomToViewConstraint.constant = -self.tabBar.bounds.size.height;
            return _playerBottomToViewConstraint;
        } else {
            return preiOS18ConstraintBlock();
        }
    } else {
        return preiOS18ConstraintBlock();
    }
}

- (NSLayoutConstraint *)playerBottomToSafeAreaConstraint
{
    if (! _playerBottomToSafeAreaConstraint) {
        _playerBottomToSafeAreaConstraint = [self.miniPlayerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
    }
    return _playerBottomToSafeAreaConstraint;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // The mini player is not available for all BUs
    MiniPlayerView *miniPlayerView = [[MiniPlayerView alloc] init];
    miniPlayerView.layer.shadowOpacity = 0.9f;
    miniPlayerView.layer.shadowRadius = 5.f;
    [self.view insertSubview:miniPlayerView belowSubview:self.tabBar];
    self.miniPlayerView = miniPlayerView;
    
    miniPlayerView.translatesAutoresizingMaskIntoConstraints = NO;
    @weakify(self)
    [miniPlayerView addObserver:self keyPath:@keypath(miniPlayerView.active) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        [self updateLayoutAnimated:YES];
    }];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveNotification:)
                                               name:PushServiceDidReceiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pushServiceBadgeDidChange:)
                                               name:PushServiceBadgeDidChangeNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pushServiceStatusDidChange:)
                                               name:PushServiceStatusDidChangeNotification
                                             object:nil];
    
    [self updateLayoutAnimated:NO];
}

#pragma mark Responsiveness

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateLayoutAnimated:NO];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateLayoutAnimated:NO];
}

#pragma mark Status bar

- (BOOL)prefersStatusBarHidden
{
    return [self.selectedViewController prefersStatusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.selectedViewController preferredStatusBarStyle];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.selectedViewController preferredStatusBarUpdateAnimation];
}

#pragma mark Overrides

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    [super setSelectedViewController:selectedViewController];
    
    ApplicationSettingSetLastOpenedTabBarItemIdentifier(selectedViewController.tabBarItem.tag);
}

#pragma mark Appearance

- (void)customizeAppearance
{
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithDefaultBackground];
    
    // Remove the separator (looks nicer)
    appearance.shadowColor = UIColor.clearColor;
    
    UIFont *font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightRegular fixedSize:12.f];
    UIColor *normalForegroundColor = UIColor.srg_gray96Color;
    UIColor *selectedForegroundColor = UIColor.whiteColor;
    
    NSDictionary<NSAttributedStringKey, id> *normalItemAttributes = @{
        NSFontAttributeName : font,
        NSForegroundColorAttributeName : normalForegroundColor
    };
    
    NSDictionary<NSAttributedStringKey, id> *selectedItemAttributes = @{
        NSFontAttributeName : font,
        NSForegroundColorAttributeName : selectedForegroundColor
    };
    
    UITabBarItemAppearance *stackedItemAppearance = [[UITabBarItemAppearance alloc] initWithStyle:UITabBarItemAppearanceStyleStacked];
    stackedItemAppearance.normal.titleTextAttributes = normalItemAttributes;
    stackedItemAppearance.normal.iconColor = normalForegroundColor;
    stackedItemAppearance.selected.titleTextAttributes = selectedItemAttributes;
    stackedItemAppearance.selected.iconColor = selectedForegroundColor;
    appearance.stackedLayoutAppearance = stackedItemAppearance;
    
    UITabBarItemAppearance *inlineItemAppearance = [[UITabBarItemAppearance alloc] initWithStyle:UITabBarItemAppearanceStyleInline];
    inlineItemAppearance.normal.titleTextAttributes = normalItemAttributes;
    inlineItemAppearance.normal.iconColor = normalForegroundColor;
    inlineItemAppearance.selected.titleTextAttributes = selectedItemAttributes;
    inlineItemAppearance.selected.iconColor = selectedForegroundColor;
    appearance.inlineLayoutAppearance = inlineItemAppearance;
    
    UITabBar *tabBar = self.tabBar;
    tabBar.standardAppearance = appearance;
}

#pragma mark View controllers

- (UIViewController *)videosTabViewController
{
    UITabBarItem *videosTabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Videos", @"Videos tab title")
                                                                   image:[UIImage imageNamed:@"videos_tab"]
                                                                     tag:TabBarItemIdentifierVideos];
    videosTabBarItem.accessibilityIdentifier = [AccessibilityIdentifierObjC identifier:AccessibilityIdentifierVideosTabBarItem].value;
    
    PageViewController *pageViewController = [PageViewController videosViewController];
    NavigationController *videosNavigationController = [[NavigationController alloc] initWithRootViewController:pageViewController];
    videosNavigationController.tabBarItem = videosTabBarItem;
    return videosNavigationController;
}

- (UITabBarItem *)audiosTabBarItem
{
    UITabBarItem *audiosTabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Audios", @"Audios tab title")
                                                                   image:[UIImage imageNamed:@"audios_tab"]
                                                                     tag:TabBarItemIdentifierAudios];
    audiosTabBarItem.accessibilityIdentifier = [AccessibilityIdentifierObjC identifier:AccessibilityIdentifierAudiosTabBarItem].value;
    return audiosTabBarItem;
}

- (UIViewController *)audiosTabViewController
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    
    if (applicationConfiguration.audioContentHomepagePreferred) {
        PageViewController *pageViewController = [PageViewController audiosViewController];
        NavigationController *audiosNavigationController = [[NavigationController alloc] initWithRootViewController:pageViewController];
        audiosNavigationController.tabBarItem = [self audiosTabBarItem];
        return audiosNavigationController;
    }
    else {
        NSArray<RadioChannel *> *radioChannels = applicationConfiguration.radioHomepageChannels;
        if (radioChannels.count > 1) {
            UIViewController *radioChannelsViewController = [[RadioChannelsViewController alloc] initWithRadioChannels:radioChannels];
            NavigationController *audiosNavigationController = [[NavigationController alloc] initWithRootViewController:radioChannelsViewController];
            audiosNavigationController.tabBarItem = [self audiosTabBarItem];
            return audiosNavigationController;
        }
        else if (radioChannels.count == 1) {
            RadioChannel *radioChannel = radioChannels.firstObject;
            PageViewController *pageViewController = [PageViewController audiosViewControllerForRadioChannel:radioChannel];
            NavigationController *audiosNavigationController = [[NavigationController alloc] initWithRootViewController:pageViewController];
            audiosNavigationController.tabBarItem = [self audiosTabBarItem];
            [audiosNavigationController updateWithRadioChannel:radioChannel animated:NO];
            return audiosNavigationController;
        }
        else {
            return nil;
        }
    }
}

- (UIViewController *)livestreamsTabViewController
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    
    NSArray<NSNumber *> *liveHomeSections = applicationConfiguration.liveHomeSections;
    if (liveHomeSections.count != 0) {
        UITabBarItem *liveTabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Livestreams", @"Livestreams tab bar title")
                                                                     image:[UIImage imageNamed:@"livestreams_tab"]
                                                                       tag:TabBarItemIdentifierLivestreams];
        liveTabBarItem.accessibilityIdentifier = [AccessibilityIdentifierObjC identifier:AccessibilityIdentifierLivestreamsTabBarItem].value;
        
        PageViewController *pageViewController = [PageViewController liveViewController];
        NavigationController *liveNavigationController = [[NavigationController alloc] initWithRootViewController:pageViewController];
        liveNavigationController.tabBarItem = liveTabBarItem;
        return liveNavigationController;
    }
    else {
        return nil;
    }
}

- (UIViewController *)searchTabViewController
{
    UITabBarItem *searchTabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Search", @"Search tab bar title")
                                                                   image:[UIImage imageNamed:@"search_tab"]
                                                                     tag:TabBarItemIdentifierSearch];
    searchTabBarItem.accessibilityIdentifier = [AccessibilityIdentifierObjC identifier:AccessibilityIdentifierSearchTabBarItem].value;
    
    UIViewController *searchViewController = [SearchViewController viewController];
    NavigationController *searchNavigationController = [[NavigationController alloc] initWithRootViewController:searchViewController];
    searchNavigationController.tabBarItem = searchTabBarItem;
    return searchNavigationController;
}

- (UIViewController *)profileTabViewController
{
    UITabBarItem *profileTabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Profile", @"Profile tab bar title")
                                                                    image:[UIImage imageNamed:@"profile_tab"]
                                                                      tag:TabBarItemIdentifierProfile];
    profileTabBarItem.accessibilityIdentifier = [AccessibilityIdentifierObjC identifier:AccessibilityIdentifierProfileTabBarItem].value;
    
    UIViewController *profileViewController = [[ProfileViewController alloc] init];
    NavigationController *profileNavigationController = [[NavigationController alloc] initWithRootViewController:profileViewController];
    
    SplitViewController *profileSplitViewController = [[SplitViewController alloc] init];
    profileSplitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
    profileSplitViewController.viewControllers = @[ profileNavigationController ];
    profileSplitViewController.tabBarItem = profileTabBarItem;
    return profileSplitViewController;
}

#pragma mark Layout

- (void)updateLayoutAnimated:(BOOL)animated
{
    void (^animations)(void) = ^{
        if (! UIAccessibilityIsVoiceOverRunning() && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            // Use 1/3 of the space, minimum of 500 pixels. If the player cannot fit in 80% of the screen,
            // use all available space.
            CGFloat availableWidth = CGRectGetWidth(self.view.frame) - 2 * self.miniPlayerOffset;
            CGFloat width = fmaxf(availableWidth / 3.f, 500.f);
            if (width > 0.8f * availableWidth) {
                width = availableWidth;
            }
            
            self.playerWidthConstraint.constant = width;
            self.playerWidthConstraint.active = YES;
            
            self.playerLeadingConstraint.active = NO;
        }
        else {
            self.playerWidthConstraint.active = NO;
            
            self.playerLeadingConstraint.constant = self.miniPlayerOffset;
            self.playerLeadingConstraint.active = YES;
        }
        
        self.playerTrailingConstraint.constant = -self.miniPlayerOffset;
        self.playerTrailingConstraint.active = YES;
        
        if (self.miniPlayerView.active) {
            self.playerHeightConstraint.constant = MiniPlayerHeight;
            self.playerBottomToSafeAreaConstraint.constant = -self.miniPlayerOffset;
        }
        else {
            self.playerHeightConstraint.constant = 0.f;
            self.playerBottomToSafeAreaConstraint.constant = 0.f;
        }
        
        self.playerHeightConstraint.active = YES;
        BOOL isRegular = (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular);
        self.playerBottomToViewConstraint.active = ! isRegular;
        self.playerBottomToSafeAreaConstraint.active = isRegular;

        CALayer *miniPlayerLayer = self.miniPlayerView.layer;
        if (UIAccessibilityIsVoiceOverRunning()) {
            miniPlayerLayer.cornerRadius = 0.f;
            miniPlayerLayer.masksToBounds = NO;
        }
        else {
            miniPlayerLayer.cornerRadius = LayoutStandardViewCornerRadius;
            miniPlayerLayer.masksToBounds = YES;
        }
        
        [self play_setNeedsContentInsetsUpdate];
    };
    
    // Only animate if the view is part of a view hierarchy
    if (animated && self.view.window) {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.2 animations:^{
            animations();
            [self.view layoutIfNeeded];
        }];
    }
    else {
        animations();
    }
}

- (void)updateProfileTabBarItem
{
    UITabBarItem *profileTabBarItem = [self tabBarItemForIdentifier:TabBarItemIdentifierProfile];
    NSInteger badgeNumber = UIApplication.sharedApplication.applicationIconBadgeNumber;
    
    if (PushService.sharedService.enabled && profileTabBarItem && badgeNumber != 0) {
        profileTabBarItem.badgeValue = (badgeNumber > 99) ? @"99+" : @(badgeNumber).stringValue;
        profileTabBarItem.badgeColor = UIColor.play_notificationRed;
    }
    else {
        profileTabBarItem.badgeValue = nil;
    }
}

- (UITabBarItem *)tabBarItemForIdentifier:(TabBarItemIdentifier)TabBarItemIdentifier
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(UITabBarItem.new, tag), @(TabBarItemIdentifier)];
    return [self.tabBar.items filteredArrayUsingPredicate:predicate].firstObject;
}

#pragma mark Push and pop

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([self.selectedViewController respondsToSelector:@selector(pushViewController:animated:)]) {
        [self.selectedViewController pushViewController:viewController animated:animated];
    }
}

#pragma mark ContainerContentInsets protocol

- (UIEdgeInsets)play_additionalContentInsets
{
    return UIEdgeInsetsMake(0.f, 0.f, self.miniPlayerView.active ? (MiniPlayerHeight + self.miniPlayerOffset) : 0.f, 0.f);
}

#pragma mark Oriented protocol

- (UIInterfaceOrientationMask)play_supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (NSArray<UIViewController *> *)play_orientingChildViewControllers
{
    return @[self.selectedViewController];
}

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    for (UIViewController *viewController in self.viewControllers) {
        if ([viewController conformsToProtocol:@protocol(PlayApplicationNavigation)]) {
            UIViewController<PlayApplicationNavigation> *navigableViewController = (UIViewController<PlayApplicationNavigation> *)viewController;
            if ([navigableViewController openApplicationSectionInfo:applicationSectionInfo]) {
                self.selectedViewController = navigableViewController;
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark ScrollableContentContainer protocol

- (UIViewController *)play_scrollableChildViewController
{
    return self.selectedViewController;
}

#pragma mark UITabBarControllerDelegate protocol

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if (viewController == self.selectedViewController) {
        if ([viewController conformsToProtocol:@protocol(TabBarActionable)]) {
            UIViewController<TabBarActionable> *actionableViewController = (UIViewController<TabBarActionable> *)viewController;
            [actionableViewController performActiveTabActionAnimated:YES];
        }
    }
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    [self play_setNeedsScrollableViewUpdate];
}

#pragma mark Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    // Ensure correct notification button availability after dismissal of the initial system alert (displayed once at most),
    // asking the user to enable push notifications.
    [self updateProfileTabBarItem];
}

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self updateLayoutAnimated:YES];
}

- (void)didReceiveNotification:(NSNotification *)notification
{
    [self updateProfileTabBarItem];
}

- (void)pushServiceBadgeDidChange:(NSNotification *)notification
{
    [self updateProfileTabBarItem];
}

- (void)pushServiceStatusDidChange:(NSNotification *)notification
{
    [self updateProfileTabBarItem];
}

@end
