//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ProfileViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationSectionInfo.h"
#import "Layout.h"
#import "NavigationController.h"
#import "NSBundle+PlaySRG.h"
#import "PlaySRG-Swift.h"
#import "ProfileAccountHeaderView.h"
#import "ProfileTableViewCell.h"
#import "PushService.h"
#import "TableView.h"
#import "UIColor+PlaySRG.h"
#import "UIDevice+PlaySRG.h"
#import "UIScrollView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import SRGAppearance;
@import SRGIdentity;

@interface ProfileViewController ()

@property (nonatomic) NSArray<ApplicationSectionInfo *> *sectionInfos;
@property (nonatomic) ApplicationSectionInfo *currentSectionInfo;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation ProfileViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [self initFromStoryboard]) {
        self.title = NSLocalizedString(@"Profile", @"Title displayed at the top of the profile view");
    }
    return self;
}

- (instancetype)initFromStoryboard
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    return storyboard.instantiateInitialViewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.srg_gray16Color;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    
    TableViewConfigure(self.tableView);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    if (SRGIdentityService.currentIdentityService) {
        self.tableView.tableHeaderView = [ProfileAccountHeaderView view];
    }
    
    [self.tableView registerReusableNotificationCell];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationWillResignActive:)
                                               name:UIApplicationWillResignActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pushServiceDidReceiveNotification:)
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
    
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(settings:)];
    settingsBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Settings", @"Settings button label on home view");
    self.navigationItem.rightBarButtonItem = settingsBarButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [PushService.sharedService resetApplicationBadge];
    
    // Ensure latest notifications are displayed
    [self reloadData];
    
    // On iPad where split screen can be used, load the secondary view afterwards (if loaded too early it will be collapsed
    // automatically onto the primary at startup for narrow layouts, which is not what we want). We must still avoid
    // overriding a section if already installed before by application shorcuts.
    if (! self.currentSectionInfo && [self play_isMovingToParentViewController] && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self openApplicationSectionInfo:self.sectionInfos.firstObject interactive:NO animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self play_isMovingFromParentViewController]) {
        [PushService.sharedService resetApplicationBadge];
    }
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

- (void)updateForContentSizeCategory
{
    [super updateForContentSizeCategory];
    
    [self reloadTableView];
}

#pragma mark Data

- (void)reloadTableView
{
    [self.tableView reloadData];
    [self updateSelection];
}

- (void)reloadData
{
    self.sectionInfos = [ApplicationSectionInfo profileApplicationSectionInfosWithNotificationPreview:self.splitViewController.collapsed];
    [self reloadTableView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView flashScrollIndicators];
    });
}

#pragma mark Helpers

- (UserNotification *)notificationAtIndexPath:(NSIndexPath *)indexPath
{
    ApplicationSectionInfo *applicationSectionInfo = self.sectionInfos[indexPath.row];
    if (applicationSectionInfo.applicationSection != ApplicationSectionNotifications) {
        return nil;
    }
    
    return applicationSectionInfo.options[ApplicationSectionOptionNotificationKey];
}

- (UIViewController *)viewControllerForSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    if (! applicationSectionInfo) {
        return nil;
    }
    
    UIViewController *viewController = nil;
    switch (applicationSectionInfo.applicationSection) {
        case ApplicationSectionNotifications: {
            viewController = [SectionViewController notificationsViewController];
            break;
        }
            
        case ApplicationSectionHistory: {
            viewController = [SectionViewController historyViewController];
            break;
        }
            
        case ApplicationSectionFavorites: {
            viewController = [SectionViewController favoriteShowsViewController];
            break;
        }
            
        case ApplicationSectionWatchLater: {
            viewController = [SectionViewController watchLaterViewController];
            break;
        }
            
        case ApplicationSectionDownloads: {
            viewController = [SectionViewController downloadsViewController];
            break;
        }
            
        default: {
            break;
        }
    }
    
    if (! viewController) {
        return nil;
    }
    
    // Always wrap into a navigation controller. The split view takes care of moving view controllers between navigation
    // controllers when collapsing or expanding
    return [[NavigationController alloc] initWithRootViewController:viewController];
}

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo interactive:(BOOL)interactive animated:(BOOL)animated
{
    if (! applicationSectionInfo) {
        return NO;
    }
    
    // Do not reload a section if already the current one (just return to the navigation root if possible)
    if (! self.splitViewController.collapsed && [applicationSectionInfo isEqual:self.currentSectionInfo]) {
        NSArray<UIViewController *> *viewControllers = self.splitViewController.viewControllers;
        if (viewControllers.count == 2) {
            UIViewController *detailViewController = viewControllers[1];
            if ([detailViewController isKindOfClass:UINavigationController.class]) {
                UINavigationController *detailNavigationController = (UINavigationController *)detailViewController;
                [detailNavigationController popToRootViewControllerAnimated:animated];
            }
        }
        return YES;
    }
    
    UIViewController *viewController = [self viewControllerForSectionInfo:applicationSectionInfo];
    if (viewController) {
        self.currentSectionInfo = applicationSectionInfo;
        
        if (interactive) {
            void (^showDetail)(void) = ^{
                [self.splitViewController showDetailViewController:viewController sender:self];
            };
            
            if (animated) {
                showDetail();
            }
            else {
                [UIView performWithoutAnimation:showDetail];
            }
        }
        else {
            // Adding the details view controller on-the-fly avoids automatic collapsing (i.e. starting with the details
            // on top of the primary) when starting in compact layout.
            NSMutableArray<UIViewController *> *viewControllers = self.splitViewController.viewControllers.mutableCopy;
            if (viewControllers.count == 1) {
                [viewControllers addObject:viewController];
            }
            else if (viewControllers.count == 2) {
                [viewControllers replaceObjectAtIndex:1 withObject:viewController];
            }
            else {
                return NO;
            }
            self.splitViewController.viewControllers = viewControllers.copy;
            [self updateSelection];
        }
        
        // Transfer the VoiceOver focus automatically, as is for example done in the Settings application.
        if (! self.splitViewController.collapsed) {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, viewController.view);
        }
        return YES;
    }
    else {
        return NO;
    }
}

- (void)updateSelection
{
    if (! self.currentSectionInfo) {
        return;
    }
    
    NSUInteger index = [self.sectionInfos indexOfObject:self.currentSectionInfo];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    else {
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        if (indexPath) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

#pragma mark ContentInsets protocol

- (NSArray<UIScrollView *> *)play_contentScrollViews
{
    return self.tableView ? @[self.tableView] : nil;
}

- (UIEdgeInsets)play_paddingContentInsets
{
    return SRGIdentityService.currentIdentityService ? UIEdgeInsetsZero : LayoutPaddingContentInsets;
}

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    return [self openApplicationSectionInfo:applicationSectionInfo interactive:YES animated:NO];
}

#pragma mark ScrollableContent protocol

- (UIScrollView *)play_scrollableView
{
    return self.tableView;
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitleHome;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelUser ];
}

#pragma mark TabBarActionable protocol

- (void)performActiveTabActionAnimated:(BOOL)animated
{
    [self.tableView play_scrollToTopAnimated:animated];
}

#pragma mark UIScrollViewDelegate protocol

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    [scrollView play_scrollToTopAnimated:YES];
    return NO;
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sectionInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self notificationAtIndexPath:indexPath]) {
        return [tableView dequeueReusableNotificationCellFor:indexPath];
    }
    else {
        return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(ProfileTableViewCell.class) forIndexPath:indexPath];
    }
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self notificationAtIndexPath:indexPath]) {
        return [[MediaCellSize fullWidth] constrainedBy:tableView].height + LayoutMargin;
    }
    else {
        return ProfileTableViewCell.height;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserNotification *notification = [self notificationAtIndexPath:indexPath];
    if (notification) {
        UITableViewCell<NotificationSettable> *notificationTableViewCell = (UITableViewCell<NotificationSettable> *)cell;
        notificationTableViewCell.notification = notification;
    }
    else {
        ProfileTableViewCell *profileTableViewCell = (ProfileTableViewCell *)cell;
        profileTableViewCell.applicationSectionInfo = self.sectionInfos[indexPath.row];
        profileTableViewCell.selectionStyle = self.splitViewController.collapsed ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserNotification *notification = [self notificationAtIndexPath:indexPath];
    if (notification) {
        // [NotificationsViewController openNotification:notification fromViewController:self];
        
        // Update the cell dot right away
        [self reloadTableView];
    }
    else {
        ApplicationSectionInfo *applicationSectionInfo = self.sectionInfos[indexPath.row];
        [self openApplicationSectionInfo:applicationSectionInfo interactive:YES animated:YES];
    }
}

#pragma mark Actions

- (void)settings:(id)sender
{
    UIViewController *settingsNavigationViewController = [SettingsNavigationViewController viewController];
    [self presentViewController:settingsNavigationViewController animated:YES completion:nil];
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self reloadData];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (self.play_viewVisible) {
        [PushService.sharedService resetApplicationBadge];
        
        // Ensure correct notification badge on notification cell availability after dismissal of the initial system alert
        // (displayed once at most), asking the user to enable push notifications.
        [self reloadData];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    if (self.play_viewVisible) {
        [PushService.sharedService resetApplicationBadge];
    }
}

- (void)pushServiceDidReceiveNotification:(NSNotification *)notification
{
    [self reloadData];
}

- (void)pushServiceBadgeDidChange:(NSNotification *)notification
{
    [self reloadData];
}

- (void)pushServiceStatusDidChange:(NSNotification *)notification
{
    [self reloadData];
}

@end
