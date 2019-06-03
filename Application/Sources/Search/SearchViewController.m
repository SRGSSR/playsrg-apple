//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchViewController.h"

#import "MediaCollectionViewCell.h"
#import "ShowCollectionViewCell.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <Masonry/Masonry.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

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
    
    NSString *showCellIdentifier = NSStringFromClass(ShowCollectionViewCell.class);
    UINib *showCellNib = [UINib nibWithNibName:showCellIdentifier bundle:nil];
    [self.collectionView registerNib:showCellNib forCellWithReuseIdentifier:showCellIdentifier];
    
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
            make.height.equalTo(@42.);
        }];
    }
    
    if (self.closeBlock) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Close button title")
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(close:)];
    }
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
    SRGPaginatedMediaSearchCompletionBlock searchResultsMediasCompletionBlock = ^(NSArray<NSString *> * _Nullable mediaURNs, NSNumber *total, SRGMediaAggregations *aggregation, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
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
    };
    
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    SRGVendor vendor = applicationConfiguration.vendor;
    NSUInteger pageSize = applicationConfiguration.pageSize;
    
    // FIXME: Probably need to build the search text by replacing with changed
    SRGPageRequest *mediaRequest = [[[SRGDataProvider.currentDataProvider mediasForVendor:vendor matchingQuery:self.searchBar.text withFilters:nil completionBlock:searchResultsMediasCompletionBlock] requestWithPageSize:pageSize] requestWithPage:page];
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

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self shouldPerformRefreshRequest] ? self.items.count : 0.f;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(MediaCollectionViewCell.class)
                                                     forIndexPath:indexPath];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    MediaCollectionViewCell *mediaCell = (MediaCollectionViewCell *)cell;
    mediaCell.media = self.items[indexPath.row];
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

#pragma mark UISearchBarDelegate protocol

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
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

- (void)close:(id)sender
{
    NSAssert(self.closeBlock, @"Close must only be available if a close block has been defined");
    self.closeBlock();
}

@end
