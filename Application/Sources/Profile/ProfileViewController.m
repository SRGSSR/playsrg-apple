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
#import "PushService.h"
#import "TableView.h"
#import "UIDevice+PlaySRG.h"
#import "UIScrollView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import SRGAppearance;
@import SRGIdentity;

@interface ProfileViewController ()

@property (nonatomic) NSArray<NSArray<ApplicationSectionInfo *> *> *sectionInfos;
@property (nonatomic) ApplicationSectionInfo *currentSectionInfo;

@property (nonatomic, weak) UITableView *tableView;

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
    
    self.view.backgroundColor = UIColor.srg_gray16Color;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor]
    ]];
    
    TableViewConfigure(self.tableView);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    if (SRGIdentityService.currentIdentityService) {
        self.tableView.tableHeaderView = [self.tableView profileAccountHeaderView];
    }
    
    [self.tableView registerReusableProfileCell];
    [self.tableView registerReusableProfileSectionHeader];
    
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
        [self openApplicationSectionInfo:self.sectionInfos.firstObject.firstObject interactive:NO animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self play_isMovingFromParentViewController]) {
        [PushService.sharedService resetApplicationBadge];
    }
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
    self.sectionInfos = [NSArray arrayWithObjects:
                         [ApplicationSectionInfo profileApplicationSectionInfos],
                         [ApplicationSectionInfo helpApplicationSectionInfos],
                         nil];
    
    [ApplicationSectionInfo profileApplicationSectionInfos];
    [self reloadTableView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView flashScrollIndicators];
    });
}

#pragma mark Helpers

- (BOOL)openHelpSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    if (! applicationSectionInfo) {
        return NO;
    }
    
    BOOL opened = NO;
    switch (applicationSectionInfo.applicationSection) {
        case ApplicationSectionFAQs: {
            opened = [ProfileHelp showFaqs];
            break;
        }
        
        case ApplicationSectionTechnicaIssue: {
            opened = [ProfileHelp showSupporByEmail];
            break;
        }
            
        case ApplicationSectionFeedback: {
            opened = [ProfileHelp showFeedbackForm];
            break;
        }
            
        case ApplicationSectionEvaluateApplication: {
            opened = [ProfileHelp showStorePage];
            break;
        }
            
        default: {
            break;
        }
    }
    return opened;
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
    
    NSIndexPath *indexPath = [self indexPathForSectionInfo:applicationSectionInfo];
    
    if (indexPath.section == 0) {
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
    else if (indexPath.section == 1) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        return [self openHelpSectionInfo:applicationSectionInfo];
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
    
    NSIndexPath *indexPath = [self indexPathForSectionInfo:self.currentSectionInfo];
    
    if (indexPath.section != NSNotFound && indexPath.row != NSNotFound) {
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    else {
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        if (indexPath) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (NSIndexPath *)indexPathForSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    if (! applicationSectionInfo) {
        return [NSIndexPath indexPathForRow:NSNotFound inSection:NSNotFound];
    }
    
    NSUInteger section = NSNotFound;
    NSUInteger row = NSNotFound;
    
    for (NSUInteger i = 0; i < [self.sectionInfos count]; i++) {
        row = [self.sectionInfos[i] indexOfObject:applicationSectionInfo];
        if (row != NSNotFound) {
            section = i;
            break;
        }
    }
    
    return [NSIndexPath indexPathForRow:row inSection:section];
}


#pragma mark ContentInsets protocol

- (NSArray<UIScrollView *> *)play_contentScrollViews
{
    return self.tableView ? @[self.tableView] : nil;
}

- (UIEdgeInsets)play_paddingContentInsets
{
    return LayoutPaddingContentInsets;
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
    return self.sectionInfos.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sectionInfos[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableProfileCellFor:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return (section == 1) ? 62.f : 0.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        UITableViewHeaderFooterView<ProfileSectionSettable> *headerView = [tableView dequeueReusableProfileSectionHeader];
        headerView.title = NSLocalizedString(@"Help and contact", @"Help and contact header title");
        return headerView;
    }
    else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ProfileCellSize height] + LayoutMargin;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell<ApplicationSectionInfoSettable> *profileTableViewCell = (UITableViewCell<ApplicationSectionInfoSettable> *)cell;
    profileTableViewCell.applicationSectionInfo = self.sectionInfos[indexPath.section][indexPath.row];
    profileTableViewCell.selectionStyle = self.splitViewController.collapsed ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ApplicationSectionInfo *applicationSectionInfo = self.sectionInfos[indexPath.section][indexPath.row];
    [self openApplicationSectionInfo:applicationSectionInfo interactive:YES animated:YES];
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
