//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HistoryViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "ApplicationSection.h"
#import "History.h"
#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "Play-Swift-Bridge.h"
#import "PlayErrors.h"
#import "PlayLogger.h"
#import "TableView.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import libextobjc;
@import SRGAnalytics;
@import SRGUserData;

@interface HistoryViewController ()

@property (nonatomic) UIBarButtonItem *defaultLeftBarButtonItem;

@property (nonatomic) NSArray<NSString *> *mediaURNs;

@end

@implementation HistoryViewController

#pragma mark Getters and setters

- (NSString *)title
{
    return TitleForApplicationSection(ApplicationSectionHistory);
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.play_blackColor;
        
    TableView *tableView = [[TableView alloc] initWithFrame:view.bounds];
    tableView.allowsSelectionDuringEditing = YES;
    tableView.allowsMultipleSelectionDuringEditing = YES;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:tableView];
    self.tableView = tableView;
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.emptyTableTitle = NSLocalizedString(@"No history", @"Text displayed when no history is available");
    self.emptyTableSubtitle = NSLocalizedString(@"Recently played medias will be displayed here", @"Hint displayed when no history is available");
    self.emptyCollectionImage = [UIImage imageNamed:@"history-90"];
    
    [self.tableView registerReusableMediaCell];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(historyEntriesDidChange:)
                                               name:SRGHistoryEntriesDidChangeNotification
                                             object:SRGUserData.currentUserData.history];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                             object:nil];
    
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
    SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider mediasWithURNs:self.mediaURNs completionBlock:completionHandler] requestWithPageSize:pageSize] requestWithPage:page];
    [requestQueue addRequest:request resume:YES];
}

- (void)refreshDidFinishWithError:(NSError *)error
{
    [self updateInterfaceForEditionAnimated:NO];
    
    [super refreshDidFinishWithError:error];
}

#pragma mark Data

- (void)updateMediaURNsWithCompletionBlock:(void (^)(NSArray<NSString *> *URNs, NSArray<NSString *> *previousURNs))completionBlock
{
    NSParameterAssert(completionBlock);
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGHistoryEntry.new, date) ascending:NO];
    [SRGUserData.currentUserData.history historyEntriesMatchingPredicate:nil sortedWithDescriptors:@[sortDescriptor] completionBlock:^(NSArray<SRGHistoryEntry *> * _Nullable historyEntries, NSError * _Nullable error) {
        if (error) {
            return;
        }
        
        NSArray<NSString *> *mediaURNs = [historyEntries valueForKeyPath:@keypath(SRGHistoryEntry.new, uid)] ?: @[];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray<NSString *> *previousMediaURNs = self.mediaURNs;
            self.mediaURNs = mediaURNs;
            completionBlock(mediaURNs, previousMediaURNs);
        });
    }];
}

#pragma mark UI

- (void)updateInterfaceForEditionAnimated:(BOOL)animated
{
    if (self.items.count != 0) {
        [self.navigationItem setRightBarButtonItem:self.editButtonItem animated:animated];
    }
    else {
        [self.navigationItem setRightBarButtonItem:nil animated:animated];
    }
}

#pragma mark ContentInsets protocol

- (UIEdgeInsets)play_paddingContentInsets
{
    return LayoutStandardTableViewPaddingInsets;
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitleHistory;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelUser ];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView<MediaSettable> *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableMediaCellFor:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [MediaCellSize fullWidthWithLayoutWidth:CGRectGetWidth(tableView.frame)].height;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableView<MediaSettable> *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // FIXME: Work around crash. To reproduce, logout with the history view visible, with a slow network (repeat a few
    //        times to trigger the crash). For reasons yet to be determined, this method is called with an index path, while
    //        items is empty. This of course crashes.
    if (indexPath.row < self.items.count) {
        cell.media = self.items[indexPath.row];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) {
        return;
    }
    
    SRGMedia *media = self.items[indexPath.row];
    [self play_presentMediaPlayerWithMedia:media position:nil airPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
    
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.value = media.URN;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleHistoryOpenMedia labels:labels];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        SRGMedia *media = self.items[indexPath.row];
        
        [SRGUserData.currentUserData.history discardHistoryEntriesWithUids:@[media.URN] completionBlock:^(NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (! error) {
                    [self hideItems:@[media]];
                    [self updateInterfaceForEditionAnimated:YES];
                }
            });
        }];
        
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.value = media.URN;
        labels.source = AnalyticsSourceSwipe;
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleHistoryRemove labels:labels];
        
        completionHandler(YES);
    }];
    deleteAction.image = [UIImage imageNamed:@"delete-22"];
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

#pragma mark Actions

- (void)removeHistory:(id)sender
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
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete history", @"Title of the confirmation pop-up displayed when the user is about to delete history entries")
                                                                             message:deleteAllModeEnabled ? NSLocalizedString(@"All items will be deleted.", @"Confirmation message displayed when the user is about to delete the whole history") : NSLocalizedString(@"The selected items will be deleted.", @"Confirmation message displayed when the user is about to delete selected history entries")
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
            [SRGUserData.currentUserData.history discardHistoryEntriesWithUids:nil completionBlock:^(NSError * _Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refresh];
                });
            }];
            
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.source = AnalyticsSourceSelection;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleHistoryRemoveAll labels:labels];
        }
        else {
            NSMutableArray<NSString *> *URNs = [NSMutableArray array];
            [selectedRows enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
                SRGMedia *media = self.items[indexPath.row];
                [URNs addObject:media.URN];
                
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.value = media.URN;
                labels.source = AnalyticsSourceSelection;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleHistoryRemove labels:labels];
            }];
            
            [SRGUserData.currentUserData.history discardHistoryEntriesWithUids:URNs completionBlock:^(NSError * _Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (! error) {
                        NSArray<SRGMedia *> *medias = [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K IN %@", @keypath(SRGMedia.new, URN), URNs]];
                        [self hideItems:medias];
                        [self updateInterfaceForEditionAnimated:YES];
                    }
                });
            }];
        }
        
        if (self.tableView.isEditing) {
            [self setEditing:NO animated:YES];
        }
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark Edit mode

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [self.tableView setEditing:NO animated:animated];
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        self.defaultLeftBarButtonItem = self.navigationItem.leftBarButtonItem;
        self.editButtonItem.title = NSLocalizedString(@"Cancel", @"Title of a cancel button");
    }
    
    UIBarButtonItem *deleteBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delete-22"]
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(removeHistory:)];
    deleteBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Delete", @"Delete button label");
    
    UIBarButtonItem *leftBarButtonItem = editing ? deleteBarButtonItem : self.defaultLeftBarButtonItem;
    if (editing) {
        leftBarButtonItem.tintColor = UIColor.redColor;
    }
    [self.navigationItem setLeftBarButtonItem:leftBarButtonItem animated:animated];
    
    [self updateInterfaceForEditionAnimated:animated];
}

#pragma mark Notifications

- (void)historyEntriesDidChange:(NSNotification *)notification
{
    // Update the URN list. If we had no media retrieval with pagination, a simple diff could then be used to animate between
    // the previous list and the new one. Since we have pagination here, we can only automatially perform a refresh if a single
    // page of content is or was displayed (because other pages after it depend on the first page).
    [self updateMediaURNsWithCompletionBlock:^(NSArray<NSString *> *URNs, NSArray<NSString *> *previousURNs) {
        NSUInteger pageSize = ApplicationConfiguration.sharedApplicationConfiguration.pageSize;
        if (! [previousURNs isEqual:self.mediaURNs] && (previousURNs.count <= pageSize || self.mediaURNs.count <= pageSize)) {
            [self refresh];
        }
    }];
}

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

@end
