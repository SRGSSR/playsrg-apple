//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TabBarController.h"

#import "HomeViewController.h"
#import "LibraryViewController.h"
#import "LivestreamsViewController.h"
#import "MiniPlayerView.h"
#import "NavigationController.h"
#import "PlayApplicationNavigation.h"
#import "PushService.h"
#import "RadioChannelsViewController.h"
#import "SearchViewController.h"
#import "ApplicationSettings.h"
#import "UIColor+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <Masonry/Masonry.h>
#import <SRGAppearance/SRGAppearance.h>

static const CGFloat MiniPlayerHeight = 50.f;
static const CGFloat MiniPlayerOffset = 5.f;

@interface TabBarController ()

@property (nonatomic, weak) MiniPlayerView *miniPlayerView;

@end

@implementation TabBarController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
        
        NSMutableArray<UIViewController *> *viewControllers = NSMutableArray.array;
        NSMutableArray<UITabBarItem *> *tabBarItems = NSMutableArray.array;

        UIViewController *viewController = [[HomeViewController alloc] initWithRadioChannel:nil];
        [viewControllers addObject:viewController];
        [tabBarItems addObject:[[UITabBarItem alloc] initWithTitle:viewController.title image:[UIImage imageNamed:@"videos-25"] tag:TabBarItemIdentifierVideos]];
        
        NSArray<RadioChannel *> *radioChannels = applicationConfiguration.radioChannels;
        if (radioChannels.count > 0) {
            viewController = [[RadioChannelsViewController alloc] initWithRadioChannels:radioChannels];
            [viewControllers addObject:viewController];
            [tabBarItems addObject:[[UITabBarItem alloc] initWithTitle:viewController.title image:[UIImage imageNamed:@"audios-25"] tag:TabBarItemIdentifierAudios]];
        }
        
        NSArray<NSNumber *> *liveHomeSections = ApplicationConfiguration.sharedApplicationConfiguration.liveHomeSections;
        if (liveHomeSections.count > 0) {
            viewController = [[LivestreamsViewController alloc] initWithHomeSections:liveHomeSections];
            [viewControllers addObject:viewController];
            [tabBarItems addObject:[[UITabBarItem alloc] initWithTitle:viewController.title image:[UIImage imageNamed:@"live-25"] tag:TabBarItemIdentifierLivestreams]];
        }
        
        viewController = [[SearchViewController alloc] init];
        [viewControllers addObject:viewController];
        [tabBarItems addObject:[[UITabBarItem alloc] initWithTitle:viewController.title image:[UIImage imageNamed:@"search-25"] tag:TabBarItemIdentifierSearch]];
        
        viewController = [[LibraryViewController alloc] init];
        [viewControllers addObject:viewController];
        [tabBarItems addObject:[[UITabBarItem alloc] initWithTitle:viewController.title image:[UIImage imageNamed:@"library-25"] tag:TabBarItemIdentifierLibrary]];
        
        TabBarItemIdentifier lastOpenedTabBarItemIdentifier = ApplicationSettingLastOpenedTabBarItemIdentifier();
        
        NSMutableArray<NavigationController *> *navigationControllers = NSMutableArray.array;
        __block NSInteger initialTabIndex = 0;
        [viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
            UITabBarItem *tabBarItem = tabBarItems[idx];
            
            NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:viewController];
            navigationController.delegate = self;
            navigationController.tabBarItem = tabBarItem;
            [navigationControllers addObject:navigationController];
            
            if (tabBarItem.tag == lastOpenedTabBarItemIdentifier) {
                initialTabIndex = idx;
            }
        }];
        
        self.viewControllers = navigationControllers.copy;
        
        self.selectedIndex = initialTabIndex;
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor *foregroundColor = UIColor.whiteColor;
    
    UINavigationBar.appearance.barStyle = UIBarStyleBlack;
    UINavigationBar.appearance.tintColor = foregroundColor;
    UINavigationBar.appearance.titleTextAttributes = @{ NSFontAttributeName : [UIFont srg_mediumFontWithSize:18.f],
                                                        NSForegroundColorAttributeName : foregroundColor };
    
    for (NSNumber *controlState in @[ @(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateDisabled) ]) {
        [UIBarButtonItem.appearance setTitleTextAttributes:@{ NSFontAttributeName : [UIFont srg_regularFontWithSize:16.f],
                                                              NSForegroundColorAttributeName : foregroundColor }
                                                  forState:controlState.integerValue];
    }
    
    UITabBar.appearance.barStyle = UIBarStyleBlack;
    UITabBar.appearance.tintColor = UIColor.whiteColor;
    
    for (NSNumber *controlState in @[ @(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateDisabled) ]) {
        [UITabBarItem.appearance setTitleTextAttributes:@{ NSFontAttributeName : [UIFont srg_regularFontWithSize:12.f],
                                                           NSForegroundColorAttributeName : foregroundColor }
                                               forState:controlState.integerValue];
    }
    
    // The mini player is not available for all BUs
    MiniPlayerView *miniPlayerView = [[MiniPlayerView alloc] initWithFrame:CGRectZero];
    [self.view insertSubview:miniPlayerView belowSubview:self.tabBar];
    
    // iOS 10 bug: Cannot apply a shadow to a blurred view without breaking the blur effect
    // Probably related to radar 27189321.
    // TODO: Remove when iOS 10 is not supported anymore
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 10) {
        miniPlayerView.layer.shadowOpacity = 0.9f;
        miniPlayerView.layer.shadowRadius = 5.f;
    }
    
    self.miniPlayerView = miniPlayerView;
    
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
                                           selector:@selector(didReceiveNotification:)
                                               name:PushServiceDidReceiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(badgeDidChange:)
                                               name:PushServiceBadgeDidChangeNotification
                                             object:nil];
    
    [self updateLayoutAnimated:NO];
}

#pragma mark Rotation

- (BOOL)shouldAutorotate
{
    if (! [super shouldAutorotate]) {
        return NO;
    }
    
    return [self.selectedViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIInterfaceOrientationMask supportedInterfaceOrientations = [super supportedInterfaceOrientations];
    return supportedInterfaceOrientations & [self.selectedViewController supportedInterfaceOrientations];
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


#pragma mark Layout

- (void)updateLayoutAnimated:(BOOL)animated
{
    void (^animations)(void) = ^{
        [self.miniPlayerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            if (@available(iOS 11, *)) {
                make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(MiniPlayerOffset);
                make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).with.offset(-MiniPlayerOffset);
            }
            else {
                make.left.equalTo(self.view).with.offset(MiniPlayerOffset);
                make.right.equalTo(self.view).with.offset(-MiniPlayerOffset);
            }
            
            if (self.miniPlayerView.active) {
                make.height.equalTo(@(MiniPlayerHeight));
                make.bottom.equalTo(self.tabBar.mas_top).with.offset(-MiniPlayerOffset);
            }
            else {
                make.height.equalTo(@0);
                make.bottom.equalTo(self.tabBar.mas_top);
            }
        }];
        
        [self play_setNeedsContentInsetsUpdate];
    };
    
    if (animated) {
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

- (void)updateLibraryTabBarItem
{
    if (@available(iOS 10, *)) {
        UITabBarItem *libraryTabBarItem = [self tabBarItemForIdentifier:TabBarItemIdentifierLibrary];
        NSInteger badgeNumber = UIApplication.sharedApplication.applicationIconBadgeNumber;
        
        if (PushService.sharedService.enabled && libraryTabBarItem && badgeNumber != 0) {
            libraryTabBarItem.badgeValue = (badgeNumber > 99) ? @"99+" : @(badgeNumber).stringValue;
            libraryTabBarItem.badgeColor = UIColor.play_notificationRedColor;
        }
        else {
            libraryTabBarItem.badgeValue = nil;
        }
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
    [self.selectedViewController pushViewController:viewController animated:animated];
}

#pragma mark ContainerContentInsets protocol

- (UIEdgeInsets)play_additionalContentInsets
{
    return UIEdgeInsetsMake(0.f, 0.f, self.miniPlayerView.active ? (MiniPlayerHeight + MiniPlayerOffset) : 0.f, 0.f);
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

#pragma mark Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    // Ensure correct notification button availability after:
    //   - Dismissal of the initial system alert (displayed once at most), asking the user to enable push notifications.
    //   - Returning from system settings, where the user might have updated push notification authorizations.
    [self updateLibraryTabBarItem];
}

- (void)didReceiveNotification:(NSNotification *)notification
{
    [self updateLibraryTabBarItem];
}

- (void)badgeDidChange:(NSNotification *)notification
{
    [self updateLibraryTabBarItem];
}

@end
