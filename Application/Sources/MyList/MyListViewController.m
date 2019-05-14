//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MyListViewController.h"

#import "ApplicationConfiguration.h"
#import "MyList.h"
#import "MyListTableViewCell.h"
#import "NSBundle+PlaySRG.h"
#import "PlayErrors.h"
#import "PlayLogger.h"
#import "ShowViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"


#import <libextobjc/libextobjc.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>
#import <SRGUserData/SRGUserData.h>

@interface MyListViewController () <MyListTableViewCellDelegate>

@property (nonatomic) UIBarButtonItem *defaultLeftBarButtonItem;

@property (nonatomic) NSArray<NSString *> *showURNs;

@end

@implementation MyListViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"My List", @"Title displayed at the top of the My List screen");
    self.view.backgroundColor = UIColor.play_blackColor;
    
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    self.emptyTableTitle = NSLocalizedString(@"No content", @"Text displayed when no show added to My List");
    self.emptyTableSubtitle = (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) ? NSLocalizedString(@"You can press on a show to add it to My List", @"Hint displayed when no show added to theMy List and the device supports 3D touch") : NSLocalizedString(@"You can tap and hold a show to add it to My List", @"Hint displayed when no show added to My List and the device does not support 3D touch");
    self.emptyCollectionImage = [UIImage imageNamed:@"my_list-90"];
    
    NSString *cellIdentifier = NSStringFromClass(MyListTableViewCell.class);
    UINib *cellNib = [UINib nibWithNibName:cellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
    
    [self updateInterfaceForEditionAnimated:NO];
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

#pragma mark Overrides

- (void)refresh
{
    [self updateMediaURNsWithCompletionBlock:^(NSArray<NSString *> *URNs, NSArray<NSString *> *previousURNs) {
        [super refresh];
    }];
}

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    NSUInteger pageSize = ApplicationConfiguration.sharedApplicationConfiguration.pageSize;
    SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider showsWithURNs:self.showURNs completionBlock:completionHandler] requestWithPageSize:pageSize] requestWithPage:page];
    [requestQueue addRequest:request resume:YES];
}

- (void)refreshDidFinishWithError:(NSError *)error
{
    [self updateInterfaceForEditionAnimated:NO];
    
    [super refreshDidFinishWithError:error];
}

- (AnalyticsPageType)pageType
{
    return AnalyticsPageTypeMyList;
}

#pragma mark Data

- (void)updateMediaURNsWithCompletionBlock:(void (^)(NSArray<NSString *> *URNs, NSArray<NSString *> *previousURNs))completionBlock
{
    NSParameterAssert(completionBlock);
    
    NSArray<NSString *> *URNs = MyListShowURNs();
    NSArray<NSString *> *previousURNs = self.showURNs;
    self.showURNs = URNs;
    completionBlock(URNs, previousURNs);
}

#pragma mark UI

- (void)updateInterfaceForEditionAnimated:(BOOL)animated
{
    if (self.items.count != 0) {
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

- (UIEdgeInsets)play_paddingContentInsets
{
    return UIEdgeInsetsMake(5.f, 0.f, 10.f, 0.f);
}

#pragma mark MyListTableViewCellDelegate protocol

- (void)myListTableViewCell:(MyListTableViewCell *)myListTableViewCell deleteShow:(SRGShow *)show
{
    [self hideItems:@[show]];
    [self updateInterfaceForEditionAnimated:YES];
    
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.value = show.URN;
    labels.source = AnalyticsSourceSwipe;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleMyListRemove labels:labels];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MyListTableViewCell.class) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    return (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedAscending) ? 94.f : 110.f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(MyListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // FIXME: Work around crash. To reproduce, logout with My List view visible, with a slow network (repeat a few
    //        times to trigger the crash). For reasons yet to be determined, this method is called with an index path, while
    //        items is empty. This of course crashes.
    if (indexPath.row < self.items.count) {
        cell.show = self.items[indexPath.row];
        cell.cellDelegate = self;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) {
        return;
    }
    
    SRGShow *show = self.items[indexPath.row];
    ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:show fromPushNotification:NO];
    [self.navigationController pushViewController:showViewController animated:YES];
    
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.value = show.URN;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleMyListOpenShow labels:labels];

}

#pragma mark Actions

- (void)removeShow:(id)sender
{
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
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:deleteAllModeEnabled ? NSLocalizedString(@"Remove all content", @"Title of the confirmation pop-up displayed when the user is about to clean My List") : NSLocalizedString(@"Remove content", @"Title of the confirmation pop-up displayed when the user is about to remove selected entries from My List")
                                                                             message:deleteAllModeEnabled ? NSLocalizedString(@"Are you sure you want to delete all items?", @"Confirmation message displayed when the user is about to clean My List") : NSLocalizedString(@"Are you sure you want to delete the selected items?", @"Confirmation message displayed when the user is about to remove selected entries from My List")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Title of a cancel button") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (deleteAllModeEnabled) {
            for (NSInteger section = 0; section < self.tableView.numberOfSections; section++) {
                for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
                    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section] animated:YES];
                }
            }
        }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Title of a delete button") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSArray<NSIndexPath *> *selectedRows = self.tableView.indexPathsForSelectedRows;
        if (deleteAllModeEnabled || selectedRows.count == self.items.count) {
            MyListRemoveShows(nil);
            [self refresh];
            
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.source = AnalyticsSourceSelection;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleMyListRemoveAll labels:labels];
        }
        else {
            NSMutableArray<NSString *> *URNs = [NSMutableArray array];
            [selectedRows enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
                SRGMedia *media = self.items[indexPath.row];
                [URNs addObject:media.URN];
                
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.value = media.URN;
                labels.source = AnalyticsSourceSelection;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleMyListRemove labels:labels];
            }];
            
            MyListRemoveShows(URNs.copy);
            NSArray<SRGShow *> *shows = [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K IN %@", @keypath(SRGShow.new, URN), URNs]];
            [self hideItems:shows];
            [self updateInterfaceForEditionAnimated:YES];
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
                                                                           action:@selector(removeShow:)];
    deleteBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Delete", @"Delete button label");
    
    UIBarButtonItem *leftBarButtonItem = editing ? deleteBarButtonItem : self.defaultLeftBarButtonItem;
    if (editing) {
        leftBarButtonItem.tintColor = UIColor.redColor;
    }
    [self.navigationItem setLeftBarButtonItem:leftBarButtonItem animated:animated];
    
    [self updateInterfaceForEditionAnimated:animated];
}

#pragma mark Notifications

- (void)playlistEntriesDidChange:(NSNotification *)notification
{
    // Update the URN list. If we had no media retrieval with pagination, a simple diff could then be used to animate between
    // the previous list and the new one. Since we have pagination here, we can only automatially perform a refresh if a single
    // page of content is or was displayed (because other pages after it depend on the first page).
    [self updateMediaURNsWithCompletionBlock:^(NSArray<NSString *> *URNs, NSArray<NSString *> *previousURNs) {
        NSUInteger pageSize = ApplicationConfiguration.sharedApplicationConfiguration.pageSize;
        if (! [previousURNs isEqual:self.showURNs] && (previousURNs.count <= pageSize || self.showURNs.count <= pageSize)) {
            [self refresh];
        }
    }];
}

@end
