//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ProfileViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationSectionInfo.h"
#import "DownloadsViewController.h"
#import "FavoritesViewController.h"
#import "HistoryViewController.h"
#import "Layout.h"
#import "NavigationController.h"
#import "NotificationsViewController.h"
#import "NSBundle+PlaySRG.h"
#import "ProfileAccountHeaderView.h"
#import "ProfileTableViewCell.h"
#import "PushService.h"
#import "SettingsViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIDevice+PlaySRG.h"
#import "UIScrollView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"
#import "WatchLaterViewController.h"

#import <SRGAppearance/SRGAppearance.h>
#import <SRGIdentity/SRGIdentity.h>

@interface ProfileViewController ()

@property (nonatomic) NSArray<ApplicationSectionInfo *> *sectionInfos;
@property (nonatomic) ApplicationSectionInfo *currentSectionInfo;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation ProfileViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.title = NSLocalizedString(@"Profile", @"Title displayed at the top of the profile view");
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.play_blackColor;
    
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    if (SRGIdentityService.currentIdentityService) {
        self.tableView.tableHeaderView = [ProfileAccountHeaderView view];
    }
    
    NSString *cellIdentifier = NSStringFromClass(NotificationTableViewCell.class);
    UINib *cellNib = [UINib nibWithNibName:cellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusChanged
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveNotification:)
                                               name:PushServiceDidReceiveNotification
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
                                           selector:@selector(badgeDidChange:)
                                               name:PushServiceBadgeDidChangeNotification
                                             object:nil];
    
    UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings-22"]
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
    
    if ([self play_isMovingToParentViewController] && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
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
    
    [self.tableView reloadData];
}

#pragma mark Data

- (void)reloadData
{
    self.sectionInfos = ApplicationSectionInfo.profileApplicationSectionInfos;
    [self.tableView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSelection];
        [self.tableView flashScrollIndicators];
    });
}

#pragma mark Helpers

- (Notification *)notificationAtIndexPath:(NSIndexPath *)indexPath
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
            viewController = [[NotificationsViewController alloc] init];
            break;
        }
            
        case ApplicationSectionHistory: {
            viewController = [[HistoryViewController alloc] init];
            break;
        }
            
        case ApplicationSectionFavorites: {
            viewController = [[FavoritesViewController alloc] init];
            break;
        }
            
        case ApplicationSectionWatchLater: {
            viewController = [[WatchLaterViewController alloc] init];
            break;
        }
            
        case ApplicationSectionDownloads: {
            viewController = [[DownloadsViewController alloc] init];
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
    
    if (! self.splitViewController.collapsed && [applicationSectionInfo isEqual:self.currentSectionInfo]) {
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
    if (index == NSNotFound) {
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark ContentInsets protocol

- (NSArray<UIScrollView *> *)play_contentScrollViews
{
    return self.tableView ? @[self.tableView] : nil;
}

- (UIEdgeInsets)play_paddingContentInsets
{
    return UIEdgeInsetsZero;
}

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    return [self openApplicationSectionInfo:applicationSectionInfo interactive:YES animated:NO];
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
        return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(NotificationTableViewCell.class) forIndexPath:indexPath];
    }
    else {
        return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(ProfileTableViewCell.class) forIndexPath:indexPath];
    }
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self notificationAtIndexPath:indexPath]) {
        return LayoutTableViewCellStandardHeight + LayoutStandardMargin;
    }
    else {
        return LayoutStandardSimpleTableCellHeight();
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Notification *notification = [self notificationAtIndexPath:indexPath];
    if (notification) {
        NotificationTableViewCell *notificationTableViewCell = (NotificationTableViewCell *)cell;
        notificationTableViewCell.notification = notification;
    }
    else {
        ProfileTableViewCell *profileTableViewCell = (ProfileTableViewCell *)cell;
        profileTableViewCell.applicationSectionInfo = self.sectionInfos[indexPath.row];
        profileTableViewCell.selectionStyle = self.splitViewController.collapsed ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Notification *notification = [self notificationAtIndexPath:indexPath];
    if (notification) {
        [NotificationsViewController openNotification:notification fromViewController:self];
        
        // Update the cell dot right away
        [tableView reloadData];
    }
    else {
        ApplicationSectionInfo *applicationSectionInfo = self.sectionInfos[indexPath.row];
        [self openApplicationSectionInfo:applicationSectionInfo interactive:YES animated:YES];
    }
}

#pragma mark Actions

- (void)settings:(id)sender
{
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
    NavigationController *settingsNavigationController = [[NavigationController alloc] initWithRootViewController:settingsViewController];
    [self presentViewController:settingsNavigationController animated:YES completion:nil];
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self reloadData];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (self.viewVisible) {
        [PushService.sharedService resetApplicationBadge];
        
        // Ensure correct notification badge on notification cell availability after:
        //   - Dismissal of the initial system alert (displayed once at most), asking the user to enable push notifications.
        //   - Returning from system settings, where the user might have updated push notification authorizations.
        [self reloadData];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    if (self.viewVisible) {
        [PushService.sharedService resetApplicationBadge];
    }
}

- (void)didReceiveNotification:(NSNotification *)notification
{
    // Ensure correct latest notifications displayed
    [self reloadData];
}

- (void)badgeDidChange:(NSNotification *)notification
{
    // Ensure correct latest notifications displayed
    [self reloadData];
}

@end
