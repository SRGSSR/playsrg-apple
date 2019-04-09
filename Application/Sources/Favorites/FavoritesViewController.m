//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "FavoritesViewController.h"

#import "Banner.h"
#import "Favorite.h"
#import "FavoriteTableViewCell.h"
#import "NSBundle+PlaySRG.h"
#import "PlayErrors.h"
#import "ShowViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

@interface FavoritesViewController ()

@property (nonatomic) NSArray<Favorite *> *favorites;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) UIRefreshControl *refreshControl;

@property (nonatomic) UIBarButtonItem *defaultLeftBarButtonItem;

@end

@implementation FavoritesViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.favorites = Favorite.favorites;
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Favorites", @"Title displayed at the top of the favorites screen");
    
    self.view.backgroundColor = UIColor.play_blackColor;
    
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    NSString *cellIdentifier = NSStringFromClass(FavoriteTableViewCell.class);
    UINib *cellNib = [UINib nibWithNibName:cellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = UIColor.whiteColor;
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:refreshControl atIndex:0];
    self.refreshControl = refreshControl;
    
    [self updateInterfaceForEditionAnimated:NO];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(favoriteStateDidChange:)
                                               name:FavoriteStateDidChangeNotification
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

- (AnalyticsPageType)pageType
{
    return AnalyticsPageTypeFavorites;
}

#pragma mark UI

- (void)reloadDataAnimated:(BOOL)animated
{
    [self.tableView reloadData];
    [self updateInterfaceForEditionAnimated:animated];
}

- (void)updateInterfaceForEditionAnimated:(BOOL)animated
{
    if (self.favorites.count != 0) {
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

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSDictionary *attributes = @{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle],
                                  NSForegroundColorAttributeName : UIColor.play_lightGrayColor };
    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"No favorites", @"Text displayed when no favorites are available") attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *description = (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) ? NSLocalizedString(@"You can press on an item to add it to favorites", @"Hint displayed when no favorites are available and the device supports 3D touch") : NSLocalizedString(@"You can tap and hold an item to add it to favorites", @"Hint displayed when no favorites are available and the device does not support 3D touch");
    return [[NSAttributedString alloc] initWithString:description
                                           attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle],
                                                         NSForegroundColorAttributeName : UIColor.play_lightGrayColor }];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"favorite-90"];
}

- (UIColor *)imageTintColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return UIColor.play_lightGrayColor;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return VerticalOffsetForEmptyDataSet(scrollView);
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.favorites.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(FavoriteTableViewCell.class) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    return (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedAscending) ? 94.f : 110.f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(FavoriteTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.favorite = self.favorites[indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) {
        return;
    }
    
    Favorite *favorite = self.favorites[indexPath.row];
    [favorite objectForType:FavoriteTypeUnspecified available:NULL withCompletionBlock:^(id  _Nullable favoritedObject, NSError * _Nullable error) {
        if (error) {
            [Banner showError:error inViewController:self];
            return;
        }
        
        if ([favoritedObject isKindOfClass:SRGMedia.class]) {
            SRGMedia *media = favoritedObject;
            [self play_presentMediaPlayerWithMedia:media position:nil fromPushNotification:NO animated:YES completion:nil];
            
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.value = favorite.mediaURN;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleFavoriteOpenMedia labels:labels];
        }
        else if ([favoritedObject isKindOfClass:SRGShow.class]) {
            SRGShow *show = favoritedObject;
            ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:show fromPushNotification:NO];
            [self.navigationController pushViewController:showViewController animated:YES];
            
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.value = favorite.showURN;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleFavoriteOpenShow labels:labels];
        }
    }];
}

#pragma mark Actions

- (void)refresh:(id)sender
{
    [self refresh];
}

- (void)removeFavorites:(id)sender
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
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:deleteAllModeEnabled ? NSLocalizedString(@"Remove all favorites", @"Title of the confirmation pop-up displayed when the user is about to delete all favorite items") : NSLocalizedString(@"Remove favorites", @"Title of the confirmation pop-up displayed when the user is about to delete selected favorite items")
                                                                             message:deleteAllModeEnabled ? NSLocalizedString(@"Are you sure you want to delete all items?", @"Confirmation message displayed when the user is about to delete all favorite items") : NSLocalizedString(@"Are you sure you want to delete the selected items?", @"Confirmation message displayed when the user is about to delete selected favorite items")
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
        NSArray *selectedRows = self.tableView.indexPathsForSelectedRows;
        if (deleteAllModeEnabled || selectedRows.count == self.favorites.count) {
            [Favorite removeAllFavorites];
            self.favorites = nil;
            [self reloadDataAnimated:YES];
            
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.source = AnalyticsSourceSelection;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleFavoriteRemoveAll labels:labels];
        }
        else {
            NSMutableArray<Favorite *> *favoritesToRemove = [NSMutableArray array];
            for (NSIndexPath *selectedIndexPath in selectedRows) {
                [favoritesToRemove addObject:self.favorites[selectedIndexPath.row]];
            }
            
            for (Favorite *favorite in favoritesToRemove) {
                [Favorite removeFavorite:favorite];
                
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.value = (favorite.type == FavoriteTypeShow) ? favorite.showURN : favorite.mediaURN;
                labels.source = AnalyticsSourceSelection;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleFavoriteRemove labels:labels];
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
                                                                           action:@selector(removeFavorites:)];
    deleteBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Delete", @"Delete button label");
    
    UIBarButtonItem *leftBarButtonItem = editing ? deleteBarButtonItem : self.defaultLeftBarButtonItem;
    if (editing) {
        leftBarButtonItem.tintColor = UIColor.redColor;
    }
    [self.navigationItem setLeftBarButtonItem:leftBarButtonItem animated:animated];
    
    [self updateInterfaceForEditionAnimated:animated];
}

#pragma mark Notifications

- (void)favoriteStateDidChange:(NSNotification *)notification
{
    Favorite *favorite = notification.userInfo[FavoriteObjectKey];
    BOOL added = [notification.userInfo[FavoriteStateKey] boolValue];
    
    if ((added && self.favorites.count + 1 == Favorite.favorites.count)
            || (! added && self.favorites.count - 1 == Favorite.favorites.count)) {
        [self.tableView beginUpdates];
        if (added) {
            self.favorites = Favorite.favorites;
            NSInteger favoriteIndex = [self.favorites indexOfObject:favorite];
            [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:favoriteIndex inSection:0] ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            NSInteger favoriteIndex = [self.favorites indexOfObject:favorite];
            self.favorites = Favorite.favorites;
            [self.tableView deleteRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:favoriteIndex inSection:0] ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView endUpdates];
        
        [self updateInterfaceForEditionAnimated:YES];
    }
    else {
        self.favorites = Favorite.favorites;
        [self reloadDataAnimated:YES];
    }
}

@end
