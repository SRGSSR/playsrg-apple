//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SubscriptionsViewController.h"

#import "ApplicationConfiguration.h"
#import "NSArray+PlaySRG.h"
#import "NSBundle+PlaySRG.h"
#import "PushService.h"
#import "ShowViewController.h"
#import "SubscriptionTableViewCell.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>
#import <SRGDataProvider/SRGDataProvider.h>

@interface SubscriptionsViewController ()

@property (nonatomic) NSArray<SRGShow *> *shows;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) UIRefreshControl *refreshControl;

@property (nonatomic) UIBarButtonItem *defaultLeftBarButtonItem;

@property (nonatomic) NSError *lastRequestError;
@property (nonatomic) NSArray<SRGShow *> *requestedShows;

@end

@implementation SubscriptionsViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Subscriptions", @"Title displayed at the top of the subscriptions screen");
    
    self.view.backgroundColor = UIColor.play_blackColor;
    
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    NSString *cellIdentifier = NSStringFromClass(SubscriptionTableViewCell.class);
    UINib *cellNib = [UINib nibWithNibName:cellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = UIColor.whiteColor;
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:refreshControl atIndex:0];
    self.refreshControl = refreshControl;
    
    [self updateInterfaceForEditionAnimated:NO];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(subscriptionStateDidChange:)
                                               name:PushServiceSubscriptionStateDidChangeNotification
                                             object:nil];
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
    
    [self reloadDataAnimated:NO];
}

#pragma mark Overrides

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue
{
    self.requestedShows = [NSArray array];
    
    NSArray<NSString *> *showURNs = PushService.sharedService.subscribedShowURNs;
    NSUInteger pageSize = ApplicationConfiguration.sharedApplicationConfiguration.pageSize;
    
    @weakify(self)
    __block SRGFirstPageRequest *firstRequest = [[SRGDataProvider.currentDataProvider showsWithURNs:showURNs completionBlock:^(NSArray<SRGShow *> * _Nullable shows, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        @strongify(self)
        
        if (error) {
            [requestQueue reportError:error];
            return;
        }
        
        self.requestedShows = [self.requestedShows arrayByAddingObjectsFromArray:shows];
        if (nextPage) {
            SRGPageRequest *nextRequest = [firstRequest requestWithPage:nextPage];
            [requestQueue addRequest:nextRequest resume:YES];
        }
        else {
            firstRequest = nil;
        }
    }] requestWithPageSize:pageSize];
    [requestQueue addRequest:firstRequest resume:YES];
}

- (void)refreshDidStart
{
    self.lastRequestError = nil;
}

- (void)refreshDidFinishWithError:(NSError *)error
{
    self.lastRequestError = error;
    
    if (! error) {
        NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGShow.new, title) ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSSortDescriptor *transmissionSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGShow.new, transmission) ascending:YES];
        self.shows = [self.requestedShows sortedArrayUsingDescriptors:@[titleSortDescriptor, transmissionSortDescriptor]];
    }
    self.requestedShows = nil;
    
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

- (AnalyticsPageType)pageType
{
    return AnalyticsPageTypeSubscriptions;
}

#pragma mark UI

- (void)reloadDataAnimated:(BOOL)animated
{
    [self.tableView reloadData];
    [self updateInterfaceForEditionAnimated:animated];
}

- (void)updateInterfaceForEditionAnimated:(BOOL)animated
{
    if (self.shows.count != 0) {
        UIBarButtonItem *rightBarButtonItem = ! self.tableView.editing ? self.editButtonItem : [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Title of a cancel button")
                                                                                                                                style:UIBarButtonItemStylePlain
                                                                                                                               target:self
                                                                                                                               action:@selector(toggleEdition:)];
        [self.navigationItem setRightBarButtonItem:rightBarButtonItem animated:animated];
    }
    else {
        [self.navigationItem setRightBarButtonItem:nil animated:animated];
    }
}

#pragma mark ContentInsets protocol

- (NSArray<UIScrollView *> *)play_contentScrollViews
{
    return self.tableView ? @[self.tableView] : nil;
}

- (UIEdgeInsets)play_paddingContentInsets
{
    return UIEdgeInsetsMake(5.f, 0.f, 10.f, 0.f);
}

#pragma mark DZNEmptyDataSetSource protocol

- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView
{
    if (self.loading) {
        // DZNEmptyDataSet stretches custom views horizontally. Ensure the image stays centered and does not get
        // stretched
        UIImageView *loadingImageView = [UIImageView play_loadingImageView90WithTintColor:UIColor.play_lightGrayColor];
        loadingImageView.contentMode = UIViewContentModeCenter;
        return loadingImageView;
    }
    else {
        return nil;
    }
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    // Remark: No test for self.loading since a custom view is used in such cases
    NSDictionary<NSAttributedStringKey, id> *attributes = @{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle],
                                                             NSForegroundColorAttributeName : UIColor.play_lightGrayColor };
    
    if (PushService.sharedService.enabled) {
        if (self.lastRequestError) {
            // Multiple errors. Pick the first ones
            NSError *error = self.lastRequestError;
            if ([error hasCode:SRGNetworkErrorMultiple withinDomain:SRGNetworkErrorDomain]) {
                error = [error.userInfo[SRGNetworkErrorsKey] firstObject];
            }
            return [[NSAttributedString alloc] initWithString:error.localizedDescription
                                                   attributes:attributes];
        }
        else {
            return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"No subscriptions", @"Text displayed when no subscriptions are available")
                                                   attributes:attributes];
        }
    }
    else {
        return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Subscriptions disabled", @"Text displayed when subscriptions are disabled")
                                               attributes:attributes];
    }
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    // Remark: No test for self.loading since a custom view is used in such cases
    NSDictionary<NSAttributedStringKey, id> *attributes = @{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle],
                                                             NSForegroundColorAttributeName : UIColor.play_lightGrayColor };
    
    if (PushService.sharedService.enabled) {
        if (self.lastRequestError) {
            return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Pull to reload", @"Text displayed to inform the user she can pull a list to reload it")
                                                   attributes:attributes];
        }
        else {
            NSString *description = (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) ? NSLocalizedString(@"You can press on a show to add it to subscriptions", @"Hint displayed when no subscriptions have been made and the device supports 3D touch") : NSLocalizedString(@"You can tap and hold a show to add it to subscriptions", @"Hint displayed when no subscriptions have been made and the device does not support 3D touch");
            return [[NSAttributedString alloc] initWithString:description
                                                   attributes:attributes];
        }
    }
    else {
        return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Notifications are required to use this feature. Tap here to enable them in the system settings", @"Message displayed when the subscriptions feature is not available because notifications are not enabled in system settings")
                                               attributes:attributes];
    }
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    // Remark: No test for self.loading since a custom view is used in such cases
    if (self.lastRequestError) {
        return [UIImage imageNamed:@"error-90"];
    }
    else {
        return [UIImage imageNamed:@"subscriptions-90"];
    }
}

- (UIColor *)imageTintColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return UIColor.play_lightGrayColor;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}

- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView
{
    return ! PushService.sharedService.enabled;
}

- (void)emptyDataSet:(UIScrollView *)scrollView didTapView:(UIView *)view
{
    if (! [PushService.sharedService presentSystemAlertForPushNotifications]) {
        NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [UIApplication.sharedApplication openURL:URL];
    }
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return VerticalOffsetForEmptyDataSet(scrollView);
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return PushService.sharedService.enabled ? self.shows.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(SubscriptionTableViewCell.class) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    return (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedAscending) ? 94.f : 110.f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(SubscriptionTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.show = self.shows[indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) {
        return;
    }
    
    SRGShow *show = self.shows[indexPath.row];
    ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:show fromPushNotification:NO];
    [self.navigationController pushViewController:showViewController animated:YES];
    
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.value = show.URN;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSubscriptionOpenShow labels:labels];
}

#pragma mark Actions

- (void)refresh:(id)sender
{
    [self refresh];
}

- (void)removeSubscriptions:(id)sender
{
    if (! PushService.sharedService.enabled) {
        return;
    }
    
    NSArray *selectedRows = self.tableView.indexPathsForSelectedRows;
    
    // Tapping on the delete button without selecting a row is a shortcut to delete all items
    BOOL deleteAllModeEnabled = (selectedRows.count == 0);
    if (deleteAllModeEnabled) {
        for (NSInteger section = 0; section < self.tableView.numberOfSections; section++) {
            for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]
                                            animated:YES
                                      scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:deleteAllModeEnabled ? NSLocalizedString(@"Remove all subscriptions", @"Title of the confirmation pop-up displayed when the user is about to delete all subscription items") : NSLocalizedString(@"Remove subscriptions", @"Title of the confirmation pop-up displayed when the user is about to delete selected subscription items")
                                                                             message:deleteAllModeEnabled ? NSLocalizedString(@"Are you sure you want to delete all items?", @"Confirmation message displayed when the user is about to delete all subscription items") : NSLocalizedString(@"Are you sure you want to delete the selected items?", @"Confirmation message displayed when the user is about to delete selected subscription items")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Title of a cancel button") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (PushService.sharedService.enabled) {
            if (deleteAllModeEnabled) {
                for (NSInteger section = 0; section < self.tableView.numberOfSections; section++) {
                    for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
                        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section] animated:YES];
                    }
                }
            }
        }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Title of a delete button") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // Avoid issues if the user switches off notifications while the alert is displayed
        if (PushService.sharedService.enabled) {
            NSArray *selectedRows = self.tableView.indexPathsForSelectedRows;
            if (deleteAllModeEnabled || selectedRows.count == self.shows.count) {
                for (SRGShow *show in self.shows) {
                    [PushService.sharedService unsubscribeFromShow:show];
                }
                
                self.shows = nil;
                [self reloadDataAnimated:YES];
                
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = AnalyticsSourceSelection;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSubscriptionRemoveAll labels:labels];
            }
            else {
                NSMutableArray<SRGShow *> *subscriptionsToRemove = [NSMutableArray array];
                for (NSIndexPath *selectedIndexPath in selectedRows) {
                    [subscriptionsToRemove addObject:self.shows[selectedIndexPath.row]];
                }
                
                for (SRGShow *show in subscriptionsToRemove) {
                    [PushService.sharedService unsubscribeFromShow:show];
                    
                    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                    labels.value = show.URN;
                    labels.source = AnalyticsSourceSelection;
                    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSubscriptionRemove labels:labels];
                }
            }
        }
        
        if (self.tableView.isEditing) {
            [self setEditing:NO animated:YES];
        }
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)toggleEdition:(id)sender
{
    BOOL editing = !self.tableView.isEditing;
    [self setEditing:editing animated:YES];
}

#pragma mark Edit mode

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        self.defaultLeftBarButtonItem = self.navigationItem.leftBarButtonItem;
    }
    
    UIBarButtonItem *deleteBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delete-22"]
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(removeSubscriptions:)];
    deleteBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Delete", @"Delete button label");
    
    UIBarButtonItem *leftBarButtonItem = editing ? deleteBarButtonItem : self.defaultLeftBarButtonItem;
    if (editing) {
        leftBarButtonItem.tintColor = UIColor.redColor;
    }
    [self.navigationItem setLeftBarButtonItem:leftBarButtonItem animated:animated];
    
    [self updateInterfaceForEditionAnimated:animated];
}

#pragma mark Notifications

- (void)subscriptionStateDidChange:(NSNotification *)notification
{
    if (! PushService.sharedService.enabled) {
        return;
    }
    
    SRGShow *show = notification.userInfo[PushServiceSubscriptionObjectKey];
    BOOL added = [notification.userInfo[PushServiceSubscriptionStateKey] boolValue];
    
    NSArray<NSString *> *subscriptions = PushService.sharedService.subscribedShowURNs;
    
    if ((added && self.shows.count + 1 == subscriptions.count)
            || (! added && self.shows.count - 1 == subscriptions.count)) {
        [self.tableView beginUpdates];
        if (added) {
            NSInteger index = [subscriptions indexOfObject:show.URN];
            self.shows = [self.shows play_arrayByInsertingObject:show atIndex:index];
            
            [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:index inSection:0] ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGShow *show, NSDictionary<NSString *,id> * _Nullable bindings) {
                return ! [subscriptions containsObject:show.URN];
            }];
            SRGShow *deletedShow = [self.shows filteredArrayUsingPredicate:predicate].firstObject;
            NSInteger index = [self.shows indexOfObject:deletedShow];
            self.shows = [self.shows play_arrayByRemovingObjectAtIndex:index];
            
            [self.tableView deleteRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:index inSection:0] ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView endUpdates];
        
        [self updateInterfaceForEditionAnimated:YES];
    }
    else {
        [self refresh];
    }
}

@end
