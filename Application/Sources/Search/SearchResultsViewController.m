//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchResultsViewController.h"

#import "MediaCollectionViewCell.h"
#import "MediaPlayerViewController.h"
#import "MediaPreviewViewController.h"
#import "SearchViewController.h"
#import "ShowCollectionViewCell.h"
#import "ShowViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

static NSString *TitleForSearchOption(SearchOption searchOption)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @{ @(SearchOptionTVShows) : NSLocalizedString(@"TV shows", @"Tab name for TV show results in the search"),
                      @(SearchOptionVideos) : NSLocalizedString(@"Videos", @"Tab name for video results in the search"),
                      @(SearchOptionRadioShows) : NSLocalizedString(@"Radio shows", @"Tab name for radio show results in the search"),
                      @(SearchOptionAudios) : NSLocalizedString(@"Audios", @"Tab name for audio results in the search") };
    });
    
    return s_titles[@(searchOption)];
}

@interface SearchResultsViewController ()

@property (nonatomic) SearchOption searchOption;
@property (nonatomic, copy) NSString *searchText;
@property (nonatomic) NSNumber *total;

@end

@implementation SearchResultsViewController

#pragma mark Object lifecycle

- (instancetype)initWithSearchOption:(SearchOption)searchOption
{
    if (self = [super init]) {
        self.searchOption = searchOption;
        self.title = TitleForSearchOption(searchOption);
        
        [self updatePageItemForSearchOption:searchOption withTotal:nil];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithSearchOption:SearchOptionVideos];
}

#pragma mark Getters and setters

- (NSString *)emptyCollectionTitle
{
    return (self.searchText.length < SearchViewControllerSearchTextMinimumLength) ? NSLocalizedString(@"No results", nil) : super.emptyCollectionTitle;
}

- (NSString *)emptyCollectionSubtitle
{
    return (self.searchText.length < SearchViewControllerSearchTextMinimumLength) ? [NSString stringWithFormat:NSLocalizedString(@"Enter %@ characters or more to search", @"Placeholder text displayed in the search field when empty (with minimum number of characters freely specified)"), @(SearchViewControllerSearchTextMinimumLength)] : super.emptyCollectionSubtitle;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.play_blackColor;
    
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.emptyCollectionImage = [UIImage imageNamed:@"search-90"];
    
    NSString *mediaCellIdentifier = NSStringFromClass(MediaCollectionViewCell.class);
    UINib *mediaCellNib = [UINib nibWithNibName:mediaCellIdentifier bundle:nil];
    [self.collectionView registerNib:mediaCellNib forCellWithReuseIdentifier:mediaCellIdentifier];
    
    NSString *showCellIdentifier = NSStringFromClass(ShowCollectionViewCell.class);
    UINib *showCellNib = [UINib nibWithNibName:showCellIdentifier bundle:nil];
    [self.collectionView registerNib:showCellNib forCellWithReuseIdentifier:showCellIdentifier];
}

#pragma mark Overrides

- (BOOL)shouldPerformRefreshRequest
{    
    return (self.searchText.length >= SearchViewControllerSearchTextMinimumLength);
}

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    SRGPaginatedSearchResultMediaListCompletionBlock searchResultsMediasCompletionBlock = ^(NSArray<SRGSearchResultMedia *> * _Nullable searchResults, NSNumber * _Nonnull total, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        [self updateWithTotal:total];
        
        if (error) {
            completionHandler(nil, page, nil, HTTPResponse, error);
            return;
        }
        
        if (searchResults.count == 0) {
            completionHandler(@[], page, nil, HTTPResponse, error);
            return;
        }
        
        NSArray<NSString *> *URNs = [searchResults valueForKey:@keypath(SRGSearchResultMedia.new, URN)];
        NSUInteger pageSize = ApplicationConfiguration.sharedApplicationConfiguration.pageSize;
        SRGPageRequest *mediasRequest = [[SRGDataProvider.currentDataProvider mediasWithURNs:URNs completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull mediasPage, SRGPage * _Nullable mediasNextPage, NSHTTPURLResponse * _Nullable mediasHTTPResponse, NSError * _Nullable mediasError) {
            // Pagination must be based on the initial search results request, not on the media by URN retrieval (since
            // this last request returns the exact needed amount of medias, with no next page)
            completionHandler(medias, page, nextPage, mediasHTTPResponse, mediasError);
        }] requestWithPageSize:pageSize];
        [requestQueue addRequest:mediasRequest resume:YES];
    };
    
    SRGPaginatedSearchResultShowListCompletionBlock searchResultShowsCompletionBlock = ^(NSArray<SRGSearchResultShow *> * _Nullable searchResults, NSNumber * _Nonnull total, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        [self updateWithTotal:total];
        
        if (error) {
            completionHandler(nil, page, nil, HTTPResponse, error);
            return;
        }
        
        if (searchResults.count == 0) {
            completionHandler(@[], page, nil, HTTPResponse, error);
            return;
        }
        
        NSArray<NSString *> *URNs = [searchResults valueForKey:@keypath(SRGSearchResultShow.new, URN)];
        NSUInteger pageSize = ApplicationConfiguration.sharedApplicationConfiguration.pageSize;
        SRGPageRequest *showsRequest = [[SRGDataProvider.currentDataProvider showsWithURNs:URNs completionBlock:^(NSArray<SRGShow *> * _Nullable shows, SRGPage * _Nonnull showsPage, SRGPage * _Nullable showsNextPage, NSHTTPURLResponse * _Nullable showsHTTPResponse, NSError * _Nullable showsError) {
            // See comment above
            completionHandler(shows, page, nextPage, showsHTTPResponse, showsError);
        }] requestWithPageSize:pageSize];
        [requestQueue addRequest:showsRequest resume:YES];
    };
    
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    SRGVendor vendor = applicationConfiguration.vendor;
    NSUInteger pageSize = applicationConfiguration.pageSize;
    
    switch (self.searchOption) {
        case SearchOptionTVShows: {
            SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider tvShowsForVendor:vendor matchingQuery:self.searchText withCompletionBlock:searchResultShowsCompletionBlock] requestWithPageSize:pageSize] requestWithPage:page];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case SearchOptionVideos: {
            SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider videosForVendor:vendor matchingQuery:self.searchText withCompletionBlock:searchResultsMediasCompletionBlock] requestWithPageSize:pageSize] requestWithPage:page];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case SearchOptionRadioShows: {
            SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider radioShowsForVendor:vendor matchingQuery:self.searchText withCompletionBlock:searchResultShowsCompletionBlock] requestWithPageSize:pageSize] requestWithPage:page];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case SearchOptionAudios: {
            SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider audiosForVendor:vendor matchingQuery:self.searchText withCompletionBlock:searchResultsMediasCompletionBlock] requestWithPageSize:pageSize] requestWithPage:page];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        default: {
            return;
            break;
        }
    }
}

- (BOOL)srg_isTrackedAutomatically
{
    return NO;
}

#pragma mark Page item

- (void)updatePageItemForSearchOption:(SearchOption)searchOption withTotal:(NSNumber *)total
{
    self.total = total;
    
    NSString *title = TitleForSearchOption(searchOption);
    if (total) {
        title = [title stringByAppendingFormat:@" (%@)", total.integerValue > 99 ? @"99+" : total];
    }
    self.play_pageItem = [[PageItem alloc] initWithTitle:title image:nil];
}

- (void)updateWithTotal:(NSNumber *)total
{
    if ([self.total isEqual:total]) {
        return;
    }
    
    [self updatePageItemForSearchOption:self.searchOption withTotal:total];
}

#pragma mark Search

- (void)updateWithSearchText:(NSString *)searchText
{
    self.searchText = searchText;
    
    if (searchText.length < SearchViewControllerSearchTextMinimumLength) {
        [self updatePageItemForSearchOption:self.searchOption withTotal:nil];
    }
    
    // Perform the search with a delay to avoid triggering several search requests if updates are made in a row
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(search) object:nil];
    
    // No delay when the search text is too small. This also covers the case where the user clears the search criterium
    // with the clear button
    static NSTimeInterval kTypingSpeedThreshold = 0.3;
    NSTimeInterval delay = (searchText.length < SearchViewControllerSearchTextMinimumLength) ? 0. : kTypingSpeedThreshold;
    [self performSelector:@selector(search) withObject:nil afterDelay:delay];
}

- (void)search
{
    [self clear];
    [self refresh];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self shouldPerformRefreshRequest] ? self.items.count : 0.f;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchOption == SearchOptionVideos || self.searchOption == SearchOptionAudios) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(MediaCollectionViewCell.class)
                                                         forIndexPath:indexPath];
    }
    else {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ShowCollectionViewCell.class)
                                                         forIndexPath:indexPath];
    }
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchOption == SearchOptionVideos || self.searchOption == SearchOptionAudios) {
        MediaCollectionViewCell *mediaCell = (MediaCollectionViewCell *)cell;
        mediaCell.media = self.items[indexPath.row];
    }
    else {
        ShowCollectionViewCell *showCell = (ShowCollectionViewCell *)cell;
        showCell.show = self.items[indexPath.row];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchOption == SearchOptionVideos || self.searchOption == SearchOptionAudios) {
        SRGMedia *media = self.items[indexPath.row];
        [self play_presentMediaPlayerWithMedia:media position:nil fromPushNotification:NO animated:YES completion:nil];
    }
    else {
        SRGShow *show = self.items[indexPath.row];
        ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:show fromPushNotification:NO];
        [self.navigationController pushViewController:showViewController animated:YES];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    
    if (self.searchOption == SearchOptionVideos || self.searchOption == SearchOptionAudios) {
        // Table layout
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
    else {
        // 2 items per row on small layouts, max cell width of 210
        CGFloat width = fminf(floorf((CGRectGetWidth(collectionView.frame) - collectionViewLayout.sectionInset.left - collectionViewLayout.sectionInset.right - collectionViewLayout.minimumInteritemSpacing) / 2.f), 210.f);
        CGFloat minTextHeight = (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedAscending) ? 30.f : 50.f;
        return CGSizeMake(width, ceilf(width * 9.f / 16.f + minTextHeight));
    }
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView.dragging && !scrollView.decelerating) {
        [self.delegate searchResultsViewControllerWasDragged:self];
    }
}

@end
