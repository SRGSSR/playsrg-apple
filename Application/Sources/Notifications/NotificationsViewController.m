//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NotificationsViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "ApplicationSection.h"
#import "Banner.h"
#import "Layout.h"
#import "NSArray+PlaySRG.h"
#import "NSBundle+PlaySRG.h"
#import "NotificationTableViewCell.h"
#import "PlayErrors.h"
#import "PlaySRG-Swift.h"
#import "PushService.h"
#import "RefreshControl.h"
#import "TableView.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import SRGAppearance;

@interface NotificationsViewController ()

@property (nonatomic) NSArray<Notification *> *notifications;

@property (nonatomic, weak) TableView *tableView;
@property (nonatomic, weak) RefreshControl *refreshControl;

@end

@implementation NotificationsViewController

#pragma mark Class methods

+ (void)openNotification:(Notification *)notification fromViewController:(UIViewController *)viewController
{
    [Notification saveNotification:notification read:YES];
    
    if (notification.mediaURN) {
        [[SRGDataProvider.currentDataProvider mediaWithURN:notification.mediaURN completionBlock:^(SRGMedia * _Nullable media, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            if (error) {
                [Banner showError:error];
                return;
            }
            
            [viewController play_presentMediaPlayerWithMedia:media position:nil airPlaySuggestions:YES fromPushNotification:NO animated:YES completion:^(PlayerType playerType) {
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = notification.showURN ?: AnalyticsSourceNotification;
                labels.type = NotificationTypeString(notification.type) ?: AnalyticsTypeActionPlayMedia;
                labels.value = notification.mediaURN;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleNotificationOpen labels:labels];
            }];
        }] resume];
    }
    else if (notification.showURN) {
        [[SRGDataProvider.currentDataProvider showWithURN:notification.showURN completionBlock:^(SRGShow * _Nullable show, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            if (error) {
                [Banner showError:error];
                return;
            }
            
            SectionViewController *showViewController = [SectionViewController showViewControllerFor:show];
            [viewController.navigationController pushViewController:showViewController animated:YES];
            
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.source = AnalyticsSourceNotification;
            labels.type = NotificationTypeString(notification.type) ?: AnalyticsTypeActionDisplayShow;
            labels.value = notification.showURN;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleNotificationOpen labels:labels];
        }] resume];
    }
    else {
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.source = AnalyticsSourceNotification;
        labels.type = NotificationTypeString(notification.type) ?: AnalyticsTypeActionNotificationAlert;
        labels.value = notification.body;
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleNotificationOpen labels:labels];
    }
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.notifications = Notification.notifications;
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)title
{
    return TitleForApplicationSection(ApplicationSectionNotifications);
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.srg_gray16Color;
        
    TableView *tableView = [[TableView alloc] initWithFrame:view.bounds];
    tableView.allowsSelectionDuringEditing = YES;
    tableView.allowsMultipleSelectionDuringEditing = YES;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:tableView];
    self.tableView = tableView;
    
    RefreshControl *refreshControl = [[RefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [tableView insertSubview:refreshControl atIndex:0];
    self.refreshControl = refreshControl;
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    NSString *cellIdentifier = NSStringFromClass(NotificationTableViewCell.class);
    UINib *cellNib = [UINib nibWithNibName:cellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
        
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationWillResignActive:)
                                               name:UIApplicationWillResignActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveNotification:)
                                               name:PushServiceDidReceiveNotification
                                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [PushService.sharedService resetApplicationBadge];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self play_isMovingFromParentViewController]) {
        [PushService.sharedService resetApplicationBadge];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // Force a layout update for the empty view to that it takes into account updated content insets appropriately.
    [self.tableView reloadEmptyDataSet];
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

#pragma mark Overrides

- (void)refresh
{
    // Avoid stopping scrolling
    // See http://stackoverflow.com/a/31681037/760435
    if (self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
    
    [self reloadDataAnimated:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView flashScrollIndicators];
    });
}

#pragma mark UI

- (void)reloadDataAnimated:(BOOL)animated
{
    self.notifications = Notification.notifications;
    [self.tableView reloadData];
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

#pragma mark DZNEmptyDataSetSource protocol

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSDictionary<NSAttributedStringKey, id> *attributes = @{ NSFontAttributeName : [SRGFont fontWithStyle:SRGFontStyleH2],
                                                             NSForegroundColorAttributeName : UIColor.srg_grayC7Color };
    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"No notifications", @"Text displayed when no notifications are available")
                                           attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSDictionary<NSAttributedStringKey, id> *attributes = @{ NSFontAttributeName : [SRGFont fontWithStyle:SRGFontStyleH4],
                                                             NSForegroundColorAttributeName : UIColor.srg_grayC7Color };
    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Subscribe to shows you like to be notified when a new episode is available.", @"Message displayed when no notifications have been received")
                                           attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"subscription-background"];
}

- (UIColor *)imageTintColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return UIColor.srg_grayC7Color;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return VerticalOffsetForEmptyDataSet(scrollView);
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitleNotifications;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelUser ];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(NotificationTableViewCell.class) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[MediaCellSize fullWidth] constrainedBy:tableView].height + LayoutMargin;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(NotificationTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.notification = self.notifications[indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Notification *notification = self.notifications[indexPath.row];
    [NotificationsViewController openNotification:notification fromViewController:self];
    [tableView reloadData];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        Notification *notification = self.notifications[indexPath.row];
        
        [Notification removeNotification:notification];
        
        self.notifications = [self.notifications play_arrayByRemovingObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:indexPath.row inSection:0] ]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadEmptyDataSet];
        
        completionHandler(YES);
    }];
    deleteAction.image = [UIImage imageNamed:@"delete"];
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

#pragma mark Actions

- (void)refresh:(id)sender
{
    [self refresh];
}

#pragma mark Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (self.play_viewVisible) {
        [PushService.sharedService resetApplicationBadge];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    if (self.play_viewVisible) {
        [PushService.sharedService resetApplicationBadge];
    }
}

- (void)didReceiveNotification:(NSNotification *)notification
{
    [self refresh];
    
    if (self.play_viewVisible) {
        [PushService.sharedService resetApplicationBadge];
    }
}

@end
