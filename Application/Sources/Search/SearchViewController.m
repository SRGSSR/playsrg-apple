//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchViewController.h"

#import "ApplicationConfiguration.h"
#import "MediaCollectionViewCell.h"
#import "SearchShowListCollectionViewCell.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <Masonry/Masonry.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

static NSString * const SearchShowsResultKey = @"shows";
static NSString * const SearchMediasResultKey = @"medias";

const NSInteger SearchViewControllerSearchTextMinimumLength = 3;

@interface SearchViewController ()

@property (nonatomic, weak) UISearchBar *searchBar;

@end

@implementation SearchViewController

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
    
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.delegate = self;
    searchBar.placeholder = [NSString stringWithFormat:NSLocalizedString(@"Enter %@ characters or more", @"Placeholder text displayed in the search field when empty (must be not too longth)"), @(SearchViewControllerSearchTextMinimumLength)];
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
    
    UIBarButtonItem *filtersBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Filters"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(editFilters:)];
    [rightBarButtonItems addObject:filtersBarButtonItem];
    
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
    return (self.searchBar.text.length >= SearchViewControllerSearchTextMinimumLength);
}

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    SRGPageRequest *mediaRequest = [[[SRGDataProvider.currentDataProvider mediasForVendor:applicationConfiguration.vendor matchingQuery:self.searchBar.text withFilters:nil completionBlock:^(NSArray<NSString *> * _Nullable mediaURNs, NSNumber *total, SRGMediaAggregations *aggregation, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, page, nil, HTTPResponse, error);
            return;
        }
        
        if (mediaURNs.count == 0) {
            completionHandler(@[], page, nil, HTTPResponse, error);
            return;
        }
        
        NSUInteger pageSize = ApplicationConfiguration.sharedApplicationConfiguration.pageSize;
        SRGPageRequest *mediasRequest = [[SRGDataProvider.currentDataProvider mediasWithURNs:mediaURNs completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull mediasPage, SRGPage * _Nullable mediasNextPage, NSHTTPURLResponse * _Nullable mediasHTTPResponse, NSError * _Nullable mediasError) {
            // Pagination must be based on the initial search results request, not on the media by URN retrieval (since
            // this last request returns the exact needed amount of medias, with no next page)
            completionHandler(medias, page, nextPage, mediasHTTPResponse, mediasError);
        }] requestWithPageSize:pageSize];
        [requestQueue addRequest:mediasRequest resume:YES];
    }] requestWithPageSize:applicationConfiguration.pageSize] requestWithPage:page];
    [requestQueue addRequest:mediaRequest resume:YES];
}

- (NSString *)emptyCollectionTitle
{
    return (self.searchBar.text.length < SearchViewControllerSearchTextMinimumLength) ? NSLocalizedString(@"No results", nil) : super.emptyCollectionTitle;
}

- (NSString *)emptyCollectionSubtitle
{
    return (self.searchBar.text.length < SearchViewControllerSearchTextMinimumLength) ? [NSString stringWithFormat:NSLocalizedString(@"Enter %@ characters or more to search", @"Placeholder text displayed in the search field when empty (with minimum number of characters freely specified)"), @(SearchViewControllerSearchTextMinimumLength)] : super.emptyCollectionSubtitle;
}

#pragma mark Helpers

- (void)search
{
    [self clear];
    [self refresh];
}

- (void)sendAnalytics
{
    NSString *searchText = self.searchBar.text;
    if (searchText.length >= SearchViewControllerSearchTextMinimumLength) {
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.value = searchText;
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSearch labels:labels];
    }
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
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([self shouldPerformRefreshRequest]) {
        return (section == 0) ? 1 : self.items.count;
    }
    else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(SearchShowListCollectionViewCell.class)
                                                         forIndexPath:indexPath];
    }
    else {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(MediaCollectionViewCell.class)
                                                         forIndexPath:indexPath];
    }
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        
    }
    else {
        MediaCollectionViewCell *mediaCell = (MediaCollectionViewCell *)cell;
        mediaCell.media = self.items[indexPath.row];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGMedia *media = self.items[indexPath.row];
    [self play_presentMediaPlayerWithMedia:media position:nil fromPushNotification:NO animated:YES completion:nil];
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    
    if (indexPath.section == 0) {
        return CGSizeMake(CGRectGetWidth(collectionView.frame), 120.f);
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
    // Immediately return the view to an empty state when below the length threshold
    if (searchText.length < SearchViewControllerSearchTextMinimumLength) {
        [self.collectionView reloadData];
    }
    
    // Perform the search with a delay to avoid triggering several search requests if updates are made in a row
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(search) object:nil];
    
    // No delay when the search text is too small. This also covers the case where the user clears the search criterium
    // with the clear button
    static NSTimeInterval kTypingSpeedThreshold = 0.3;
    NSTimeInterval delay = (searchText.length < SearchViewControllerSearchTextMinimumLength) ? 0. : kTypingSpeedThreshold;
    [self performSelector:@selector(search) withObject:nil afterDelay:delay];
    
    // Add a large delay to avoid sending search events when the user is typing fast
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendAnalytics) object:nil];
    [self performSelector:@selector(sendAnalytics) withObject:nil afterDelay:3.];
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
    // TODO:
}

- (void)close:(id)sender
{
    NSAssert(self.closeBlock, @"Close must only be available if a close block has been defined");
    self.closeBlock();
}

@end
