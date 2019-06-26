//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchViewController.h"

#import "ApplicationConfiguration.h"
#import "MediaCollectionViewCell.h"
#import "NavigationController.h"
#import "SearchLoadingCollectionViewCell.h"
#import "SearchSettingsViewController.h"
#import "SearchShowListCollectionViewCell.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <Masonry/Masonry.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

@interface SearchViewController ()

@property (nonatomic) NSArray<SRGShow *> *shows;

@property (nonatomic) SRGMediaSearchSettings *settings;
@property (nonatomic) SRGMediaAggregations *aggregations;

@property (nonatomic, weak) UISearchBar *searchBar;

@property (nonatomic) SRGRequestQueue *showsRequestQueue;

@end

@implementation SearchViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.settings = [[SRGMediaSearchSettings alloc] init];
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Search", @"Search page title");
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.play_blackColor;
    
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    self.emptyCollectionImage = [UIImage imageNamed:@"search-90"];
    
    NSString *mediaCellIdentifier = NSStringFromClass(MediaCollectionViewCell.class);
    UINib *mediaCellNib = [UINib nibWithNibName:mediaCellIdentifier bundle:nil];
    [self.collectionView registerNib:mediaCellNib forCellWithReuseIdentifier:mediaCellIdentifier];
    
    NSString *showListCellIdentifier = NSStringFromClass(SearchShowListCollectionViewCell.class);
    UINib *showListCellNib = [UINib nibWithNibName:showListCellIdentifier bundle:nil];
    [self.collectionView registerNib:showListCellNib forCellWithReuseIdentifier:showListCellIdentifier];
    
    NSString *loadingCellIdentifier = NSStringFromClass(SearchLoadingCollectionViewCell.class);
    UINib *loadingCellNib = [UINib nibWithNibName:loadingCellIdentifier bundle:nil];
    [self.collectionView registerNib:loadingCellNib forCellWithReuseIdentifier:loadingCellIdentifier];
    
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.delegate = self;
    searchBar.placeholder = NSLocalizedString(@"Search", @"Placeholder text displayed in the search field when empty (must be not too long)");
    searchBar.tintColor = UIColor.play_redColor;
    searchBar.barTintColor = UIColor.clearColor;      // Avoid search bar glitch when revealed by pop in navigation controller
    self.navigationItem.titleView = searchBar;
    self.searchBar = searchBar;
    
    // The search bar height has changed on iOS 11 and breaks centering with neighboring buttons when used as title view.
    // Setting its height to 42 (!) fixes the issue. Apple recommends using a custom view with internal constraints, but
    // this does not seem to work well enough. Using a search controller is not really an option here either.
    if (@available(iOS 11, *)) {
        [searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@50.);
        }];
    }
    
    NSMutableArray<UIBarButtonItem *> *rightBarButtonItems = [NSMutableArray array];
    
    if (self.closeBlock) {
        UIBarButtonItem *closeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Close button title")
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(close:)];
        [rightBarButtonItems addObject:closeBarButtonItem];
    }
    
#if 0
    // TODO: Icon + hide when no aggregations are available
    UIBarButtonItem *filtersBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Filters"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(editFilters:)];
    [rightBarButtonItems addObject:filtersBarButtonItem];
#endif
    
    self.navigationItem.rightBarButtonItems = [rightBarButtonItems copy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self play_isMovingToParentViewController]) {
        [self.searchBar becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self play_isMovingFromParentViewController]) {
        [self.searchBar resignFirstResponder];
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

#pragma mark Overrides

- (BOOL)shouldPerformRefreshRequest
{
    return (self.searchBar.text.length != 0);
}

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    NSString *query = self.searchBar.text;
    
    SRGPageRequest *mediaSearchRequest = [[[SRGDataProvider.currentDataProvider mediasForVendor:applicationConfiguration.vendor matchingQuery:query withSettings:nil completionBlock:^(NSArray<NSString *> * _Nullable mediaURNs, NSNumber *total, SRGMediaAggregations *aggregations, NSArray<SRGSearchSuggestion *> * suggestions, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        self.aggregations = aggregations;
        
        if (error) {
            completionHandler(nil, page, nil, HTTPResponse, error);
            return;
        }
        
        if (mediaURNs.count == 0) {
            completionHandler(@[], page, nil, HTTPResponse, error);
            return;
        }
        
        SRGPageRequest *mediasRequest = [[SRGDataProvider.currentDataProvider mediasWithURNs:mediaURNs completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull mediasPage, SRGPage * _Nullable mediasNextPage, NSHTTPURLResponse * _Nullable mediasHTTPResponse, NSError * _Nullable mediasError) {
            // Pagination must be based on the initial search results request, not on the media by URN retrieval (since
            // this last request returns the exact needed amount of medias, with no next page)
            completionHandler(medias, page, nextPage, mediasHTTPResponse, mediasError);
        }] requestWithPageSize:applicationConfiguration.pageSize];
        [requestQueue addRequest:mediasRequest resume:YES];
    }] requestWithPageSize:applicationConfiguration.pageSize] requestWithPage:page];
    [requestQueue addRequest:mediaSearchRequest resume:YES];
    
    // The main list with automatic pagination management displays medias. We associate the companion show list request when
    // loading the first page only, so that both requests are made together when loading initial search results. We use the
    // maximum page size and do not manage pagination for shows. This leads to simple code withoug impacting its usability
    // (the user can still refine the search to get better results, and there are not so many shows anyway).
    if (page.number == 0) {
        static const NSUInteger kShowSearchPageSize = 20;
        
        self.showsRequestQueue = [[SRGRequestQueue alloc] initWithStateChangeBlock:^(BOOL finished, NSError * _Nullable error) {
            if (finished) {
                [self.collectionView reloadData];
            }
        }];
        
        SRGPageRequest *showSearchRequest = [[SRGDataProvider.currentDataProvider showsForVendor:applicationConfiguration.vendor matchingQuery:query mediaType:SRGMediaTypeNone withCompletionBlock:^(NSArray<NSString *> * _Nullable showURNs, NSNumber * _Nonnull total, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            if (error || showURNs.count == 0) {
                return;
            }
            
            SRGPageRequest *showsRequest = [[SRGDataProvider.currentDataProvider showsWithURNs:showURNs completionBlock:^(NSArray<SRGShow *> * _Nullable shows, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                self.shows = shows;
            }] requestWithPageSize:kShowSearchPageSize];
            [self.showsRequestQueue addRequest:showsRequest resume:YES];
        }] requestWithPageSize:kShowSearchPageSize];
        [self.showsRequestQueue addRequest:showSearchRequest resume:YES];
    }
}

- (void)didCancelRefreshRequest
{
    [self.showsRequestQueue cancel];
}

- (NSString *)emptyCollectionSubtitle
{
    return (self.searchBar.text.length == 0) ? NSLocalizedString(@"Enter something to start searching", @"Placeholder text displayed in the search field when empty") : super.emptyCollectionSubtitle;
}

#pragma mark Helpers

- (void)search
{
    self.shows = nil;
    self.aggregations = nil;
    
    [self clear];
    [self refresh];
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return self.title;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsNameForPageType(AnalyticsPageTypeSearch) ];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return (self.shows.count == 0) ? 1 : 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (! [self shouldPerformRefreshRequest]) {
        return 0;
    }
    
    if (self.shows.count != 0 && self.items.count == 0 && self.loading && section != 0) {
        return 1;
    }
    else if (self.shows.count == 0 || section != 0) {
        return self.items.count;
    }
    else {
        return 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.shows.count != 0 && self.items.count == 0 && self.loading && indexPath.section != 0) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(SearchLoadingCollectionViewCell.class)
                                                         forIndexPath:indexPath];
    }
    else if (self.shows.count == 0 || indexPath.section != 0) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(MediaCollectionViewCell.class)
                                                         forIndexPath:indexPath];
    }
    else {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(SearchShowListCollectionViewCell.class)
                                                         forIndexPath:indexPath];
    }
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:MediaCollectionViewCell.class]) {
        MediaCollectionViewCell *mediaCell = (MediaCollectionViewCell *)cell;
        mediaCell.media = self.items[indexPath.row];
    }
    else if ([cell isKindOfClass:SearchShowListCollectionViewCell.class]) {
        SearchShowListCollectionViewCell *showListCell = (SearchShowListCollectionViewCell *)cell;
        showListCell.shows = self.shows;
    }
    else if ([cell isKindOfClass:SearchLoadingCollectionViewCell.class]) {
        SearchLoadingCollectionViewCell *loadingCell = (SearchLoadingCollectionViewCell *)cell;
        [loadingCell startAnimating];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:SearchLoadingCollectionViewCell.class]) {
        SearchLoadingCollectionViewCell *loadingCell = (SearchLoadingCollectionViewCell *)cell;
        [loadingCell startAnimating];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:SearchLoadingCollectionViewCell.class]) {
        SearchLoadingCollectionViewCell *loadingCell = (SearchLoadingCollectionViewCell *)cell;
        [loadingCell startAnimating];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.shows.count != 0 && self.items.count == 0 && self.loading && indexPath.section != 0) {
        return;
    }
    else if (self.shows.count == 0 || indexPath.section != 0) {
        SRGMedia *media = self.items[indexPath.row];
        [self play_presentMediaPlayerWithMedia:media position:nil fromPushNotification:NO animated:YES completion:nil];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    
    if (self.shows.count != 0 && indexPath.section == 0) {
        CGFloat height = (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedAscending) ? 200.f : 220.f;
        return CGSizeMake(CGRectGetWidth(collectionView.frame), height);
    }
    else {
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
            CGFloat height = (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedAscending) ? 86.f : 100.f;
            return CGSizeMake(CGRectGetWidth(collectionView.frame) - collectionViewLayout.sectionInset.left - collectionViewLayout.sectionInset.right, height);
        }
        // Grid layout
        else {
            CGFloat minTextHeight = (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedAscending) ? 70.f : 100.f;
            
            static const CGFloat kItemWidth = 210.f;
            return CGSizeMake(kItemWidth, ceilf(kItemWidth * 9.f / 16.f + minTextHeight));
        }
    }
}

#pragma mark UISearchBarDelegate protocol

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Perform the search with a delay to avoid triggering several search requests if updates are made in a row
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(search) object:nil];
    
    // No delay when the search text is too small. This also covers the case where the user clears the search criterium
    // with the clear button
    static NSTimeInterval kTypingSpeedThreshold = 0.3;
    NSTimeInterval delay = (searchText.length == 0) ? 0. : kTypingSpeedThreshold;
    [self performSelector:@selector(search) withObject:nil afterDelay:delay];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView.dragging && !scrollView.decelerating) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark Actions

- (void)editFilters:(id)sender
{
    NSAssert([sender isKindOfClass:UIBarButtonItem.class], @"Bar button item expected");
    
    SearchSettingsViewController *searchFiltersViewController = [[SearchSettingsViewController alloc] initWithSettings:self.settings aggregations:self.aggregations];
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:searchFiltersViewController];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navigationController.modalPresentationStyle = UIModalPresentationPopover;
        
        UIView *barButtonItemView = [sender valueForKey:@"view"];
        if (barButtonItemView) {
            UIPopoverPresentationController *popoverPresentationController = navigationController.popoverPresentationController;
            popoverPresentationController.backgroundColor = UIColor.play_blackColor;
            popoverPresentationController.sourceView = barButtonItemView;
            popoverPresentationController.sourceRect = barButtonItemView.bounds;
        }
        
        [self presentViewController:navigationController animated:YES completion:nil];
    }
    else {
        searchFiltersViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                                                      target:self
                                                                                                                      action:@selector(closeSettings:)];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

- (IBAction)closeSettings:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)close:(id)sender
{
    NSAssert(self.closeBlock, @"Close must only be available if a close block has been defined");
    self.closeBlock();
}

@end
