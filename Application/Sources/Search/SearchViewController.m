//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "Layout.h"
#import "MostSearchedShowCollectionViewCell.h"
#import "MostSearchedShowsHeaderView.h"
#import "NavigationController.h"
#import "NSBundle+PlaySRG.h"
#import "PlaySRG-Swift.h"
#import "SearchBar.h"
#import "SearchHeaderView.h"
#import "SearchLoadingCollectionViewCell.h"
#import "SearchSettingsViewController.h"
#import "SearchShowListCollectionViewCell.h"
#import "UIColor+PlaySRG.h"
#import "UISearchBar+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import libextobjc;
@import SRGAnalytics;
@import SRGAppearance;

@interface SearchViewController () <SearchSettingsViewControllerDelegate>

@property (nonatomic) NSArray<SRGShow *> *shows;
@property (nonatomic, copy) NSString *query;

@property (nonatomic) UISearchController *searchController;
@property (nonatomic) SRGRequestQueue *showsRequestQueue;

@property (nonatomic) SRGMediaSearchSettings *settings;

@property (nonatomic, weak) UIBarButtonItem *filtersBarButtonItem;

@end

@implementation SearchViewController

#pragma mark Class methods

+ (BOOL)containsAdvancedSettings:(SRGMediaSearchSettings *)settings
{
    if (! settings) {
        return NO;
    }
    
    SRGMediaSearchSettings *defaultSettings = SearchSettingsViewController.defaultSettings;
    defaultSettings.aggregationsEnabled = NO;
    return ! [defaultSettings isEqual:settings];
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.settings = [self supportedMediaSearchSettingsFromSettings:nil];
        self.emptyCollectionImage = [UIImage imageNamed:@"search-background"];
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)title
{
    return TitleForApplicationSection(ApplicationSectionSearch);
}

#pragma mark Helpers

- (SRGMediaSearchSettings *)supportedMediaSearchSettingsFromSettings:(SRGMediaSearchSettings *)settings
{
    // A BU supporting aggregation but not displaying search settings can lead to longer response times.
    // (@see `-mediasForVendor:matchingQuery:withSettings:completionBlock:` in `SRGDataProvider`).
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    if (! applicationConfiguration.searchSettingsHidden) {
        SRGMediaSearchSettings *supportedSettings = settings ?: SearchSettingsViewController.defaultSettings;
        supportedSettings.aggregationsEnabled = NO;
        return supportedSettings;
    }
    else {
        return nil;
    }
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.srg_gray16Color;
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    // Spacing configured via delegation since dynamic
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:view.bounds collectionViewLayout:collectionViewLayout];
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    collectionView.alwaysBounceVertical = YES;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:collectionView];
    self.collectionView = collectionView;
    
    NSString *mostSearchedShowCellIdentifier = NSStringFromClass(MostSearchedShowCollectionViewCell.class);
    UINib *mostSearchedShowCellNib = [UINib nibWithNibName:mostSearchedShowCellIdentifier bundle:nil];
    [collectionView registerNib:mostSearchedShowCellNib forCellWithReuseIdentifier:mostSearchedShowCellIdentifier];

    Class showListCellClass = SearchShowListCollectionViewCell.class;
    [collectionView registerClass:showListCellClass forCellWithReuseIdentifier:NSStringFromClass(showListCellClass)];
    
    NSString *loadingCellIdentifier = NSStringFromClass(SearchLoadingCollectionViewCell.class);
    UINib *loadingCellNib = [UINib nibWithNibName:loadingCellIdentifier bundle:nil];
    [collectionView registerNib:loadingCellNib forCellWithReuseIdentifier:loadingCellIdentifier];
    
    NSString *mostSearchedShowsHeaderIdentifier = NSStringFromClass(MostSearchedShowsHeaderView.class);
    UINib *mostSearchedShowsHeaderNib = [UINib nibWithNibName:mostSearchedShowsHeaderIdentifier bundle:nil];
    [collectionView registerNib:mostSearchedShowsHeaderNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:mostSearchedShowsHeaderIdentifier];
    
    NSString *searchHeaderIdentifier = NSStringFromClass(SearchHeaderView.class);
    UINib *searchHeaderNib = [UINib nibWithNibName:searchHeaderIdentifier bundle:nil];
    [collectionView registerNib:searchHeaderNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:searchHeaderIdentifier];
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    
    UISearchBar *searchBar = self.searchController.searchBar;
    object_setClass(searchBar, SearchBar.class);
    
    searchBar.placeholder = NSLocalizedString(@"Search", @"Search placeholder text");
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.play_textField.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightRegular fixedSize:18.f];
    searchBar.delegate = self;
    searchBar.text = self.query;
    searchBar.tintColor = UIColor.whiteColor;
    
    // Required for proper search bar behavior
    self.definesPresentationContext = YES;
    
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                             object:nil];
    
    [self updateSearchSettingsButton];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self play_isMovingFromParentViewController]) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self play_isMovingFromParentViewController]) {
        // Dismiss to avoid retain cycle if the search was entered once, see https://stackoverflow.com/a/33619501/760435
        [self.searchController dismissViewControllerAnimated:NO completion:nil];
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
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    return ! applicationConfiguration.showsSearchHidden || self.query.length > 0;
}

- (void)prepareSearchResultsRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    NSString *query = self.query;
    
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    SRGPageRequest *mediaSearchRequest = [[[SRGDataProvider.currentDataProvider mediasForVendor:applicationConfiguration.vendor matchingQuery:query withSettings:self.settings completionBlock:^(NSArray<NSString *> * _Nullable mediaURNs, NSNumber * _Nullable total, SRGMediaAggregations * _Nullable aggregations, NSArray<SRGSearchSuggestion *> * _Nullable suggestions, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
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
    if (page.number == 0 && ! applicationConfiguration.showsSearchHidden && query.length > 0) {
        static const NSUInteger kShowSearchPageSize = 50;
        
        @weakify(self)
        self.showsRequestQueue = [[SRGRequestQueue alloc] initWithStateChangeBlock:^(BOOL finished, NSError * _Nullable error) {
            @strongify(self)
            if (finished) {
                [self.collectionView reloadData];
            }
        }];
        
        SRGPageRequest *showSearchRequest = [[SRGDataProvider.currentDataProvider showsForVendor:applicationConfiguration.vendor matchingQuery:query mediaType:self.settings.mediaType withCompletionBlock:^(NSArray<NSString *> * _Nullable showURNs, NSNumber * _Nonnull total, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
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

- (void)prepareMostSearchedShowsRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    SRGRequest *request = [SRGDataProvider.currentDataProvider mostSearchedShowsForVendor:applicationConfiguration.vendor matchingTransmission:SRGTransmissionNone withCompletionBlock:^(NSArray<SRGShow *> * _Nullable shows, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionHandler(shows, [SRGPage new] /* The request does not support pagination, but we need to return a page */, nil, HTTPResponse, error);
    }];
    [requestQueue addRequest:request resume:YES];
}

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    if ([self shouldDisplayMostSearchedShows]) {
        [self prepareMostSearchedShowsRefreshWithRequestQueue:requestQueue page:page completionHandler:completionHandler];
    }
    else {
        [self prepareSearchResultsRefreshWithRequestQueue:requestQueue page:page completionHandler:completionHandler];
    }
}

- (void)didCancelRefreshRequest
{
    [super didCancelRefreshRequest];
    
    [self.showsRequestQueue cancel];
}

- (NSString *)emptyCollectionTitle
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    return (applicationConfiguration.showsSearchHidden && self.query.length == 0) ? NSLocalizedString(@"Search", @"Title displayed when there is no search criterium entered") : super.emptyCollectionTitle;
}

- (NSString *)emptyCollectionSubtitle
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    return (applicationConfiguration.showsSearchHidden && self.query.length == 0) ? NSLocalizedString(@"Type to start searching", @"Message displayed when there is no search criterium entered") : super.emptyCollectionSubtitle;
}

- (BOOL)isLoading
{
    return [super isLoading] || self.showsRequestQueue.running;
}

#pragma mark UI

- (void)updateSearchSettingsButton
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    if (! applicationConfiguration.searchSettingsHidden) {
        if (! self.filtersBarButtonItem) {
            UIButton *filtersButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [filtersButton addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
            
            filtersButton.titleLabel.font = [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightRegular fixedSize:16.f];
            [filtersButton setTitle:NSLocalizedString(@"Filters", @"Filters button title") forState:UIControlStateNormal];
            [filtersButton setTitleColor:UIColor.grayColor forState:UIControlStateHighlighted];
            
            // See https://stackoverflow.com/a/25559946/760435
            static const CGFloat kInset = 2.f;
            filtersButton.imageEdgeInsets = UIEdgeInsetsMake(0.f, -kInset, 0.f, kInset);
            filtersButton.titleEdgeInsets = UIEdgeInsetsMake(0.f, kInset, 0.f, -kInset);
            filtersButton.contentEdgeInsets = UIEdgeInsetsMake(0.f, kInset, 0.f, kInset);
            
            UIBarButtonItem *filtersBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:filtersButton];
            self.navigationItem.rightBarButtonItem = filtersBarButtonItem;
            self.filtersBarButtonItem = filtersBarButtonItem;
        }
        
        id customView = self.filtersBarButtonItem.customView;
        NSAssert([customView isKindOfClass:UIButton.class], @"Expect a button by construction");
        
        UIButton *filtersButton = customView;
        UIImage *image = [SearchViewController containsAdvancedSettings:self.settings] ? [UIImage imageNamed:@"filter_on"] : [UIImage imageNamed:@"filter_off"];
        [filtersButton setImage:image forState:UIControlStateNormal];
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark Search

- (void)search
{
    self.query = self.searchController.searchBar.text;
    
    self.shows = nil;
    [self.showsRequestQueue cancel];
    
    [self updateSearchSettingsButton];
    
    [self clear];
    [self refresh];
}

#pragma mark Content visibility

- (BOOL)shouldDisplayMostSearchedShows
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    return ! applicationConfiguration.showsSearchHidden && self.query.length == 0 && ! [SearchViewController containsAdvancedSettings:self.settings];
}

- (BOOL)isDisplayingMostSearchedShows
{
    return [self shouldDisplayMostSearchedShows] && self.items.count != 0;
}

- (BOOL)isLoadingObjectsInSection:(NSInteger)section
{
    return self.shows.count != 0 && self.items.count == 0 && self.loading && section != 0;
}

- (BOOL)isDisplayingObjectsInSection:(NSInteger)section
{
    return (section == 0 && self.shows.count != 0) || (section == 1 && self.items.count != 0);
}

- (BOOL)isDisplayingMediasInSection:(NSInteger)section
{
    return self.shows.count == 0 || section != 0;
}

#pragma mark ContentInsets protocol

- (UIEdgeInsets)play_paddingContentInsets
{
    return LayoutPaddingContentInsets;
}

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    if (applicationSectionInfo.applicationSection != ApplicationSectionSearch) {
        return NO;
    }
    
    SRGMediaSearchSettings *settings = [[SRGMediaSearchSettings alloc] init];
    settings.mediaType = [applicationSectionInfo.options[ApplicationSectionOptionSearchMediaTypeOptionKey] integerValue];
    
    self.settings = [self supportedMediaSearchSettingsFromSettings:settings];
    
    NSString *query = applicationSectionInfo.options[ApplicationSectionOptionSearchQueryKey];
    if (self.searchController) {
        self.searchController.searchBar.text = query;
        [self.searchController.searchBar resignFirstResponder];
        
        [self search];
    }
    else {
        self.query = query;
    }
    
    return YES;
}

#pragma mark SearchSettingsViewControllerDelegate protocol

- (void)searchSettingsViewController:(SearchSettingsViewController *)searchSettingsViewController didUpdateSettings:(SRGMediaSearchSettings *)settings
{
    self.settings = settings;
    
    [self updateSearchSettingsButton];
    [self search];
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitleHome;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelSearch ];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if ([self shouldDisplayMostSearchedShows]) {
        return 1;
    }
    else {
        return (self.shows.count == 0) ? 1 : 2;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([self shouldDisplayMostSearchedShows]) {
        return self.items.count;
    }
    else if ([self isLoadingObjectsInSection:section]) {
        return 1;
    }
    else if ([self isDisplayingMediasInSection:section]) {
        return self.items.count;
    }
    else {
        return 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self shouldDisplayMostSearchedShows]) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(MostSearchedShowCollectionViewCell.class)
                                                         forIndexPath:indexPath];
    }
    else if ([self isLoadingObjectsInSection:indexPath.section]) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(SearchLoadingCollectionViewCell.class)
                                                         forIndexPath:indexPath];
    }
    else if ([self isDisplayingMediasInSection:indexPath.section]) {
        return [collectionView mediaCellFor:indexPath media:self.items[indexPath.row]];
    }
    else {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(SearchShowListCollectionViewCell.class)
                                                         forIndexPath:indexPath];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        if ([self isDisplayingMostSearchedShows]) {
            return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                      withReuseIdentifier:NSStringFromClass(MostSearchedShowsHeaderView.class)
                                                             forIndexPath:indexPath];
        }
        else {
            return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                      withReuseIdentifier:NSStringFromClass(SearchHeaderView.class)
                                                             forIndexPath:indexPath];
        }
    }
    else {
        return [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:MostSearchedShowCollectionViewCell.class]) {
        MostSearchedShowCollectionViewCell *mostSearchedShowCell = (MostSearchedShowCollectionViewCell *)cell;
        SRGShow *show = self.items[indexPath.row];
        mostSearchedShowCell.show = show;
    }
    else if ([cell isKindOfClass:SearchShowListCollectionViewCell.class]) {
        SearchShowListCollectionViewCell *showListCell = (SearchShowListCollectionViewCell *)cell;
        showListCell.shows = self.shows;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Highlighting disable loading animation. Remove it
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    return ! [cell isKindOfClass:SearchLoadingCollectionViewCell.class];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([view isKindOfClass:MostSearchedShowsHeaderView.class]) {
        SearchHeaderView *headerView = (SearchHeaderView *)view;
        headerView.title = NSLocalizedString(@"Most searched shows", @"Most searched shows header");
    }
    else if ([view isKindOfClass:SearchHeaderView.class]) {
        MostSearchedShowsHeaderView *headerView = (MostSearchedShowsHeaderView *)view;
        
        if ([self isDisplayingMediasInSection:indexPath.section]) {
            if (self.items != 0) {
                ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
                if (applicationConfiguration.searchSettingsHidden) {
                    if (applicationConfiguration.radioChannels.count == 0) {
                        headerView.title = NSLocalizedString(@"Videos", @"Header for video search results");
                    }
                    else {
                        headerView.title = NSLocalizedString(@"Videos and audios", @"Header for video and audio search results");
                    }
                }
                else {
                    static dispatch_once_t s_onceToken;
                    static NSDictionary<NSNumber *, NSString *> *s_titles;
                    dispatch_once(&s_onceToken, ^{
                        s_titles = @{ @(SRGMediaTypeNone) : NSLocalizedString(@"Videos and audios", @"Header for video and audio search results"),
                                      @(SRGMediaTypeVideo) : NSLocalizedString(@"Videos", @"Header for video search results"),
                                      @(SRGMediaTypeAudio) : NSLocalizedString(@"Audios", @"Header for audio search results") };
                    });
                    headerView.title = s_titles[@(self.settings.mediaType)];
                }
            }
            else {
                headerView.title = nil;
            }
        }
        else {
            headerView.title = NSLocalizedString(@"Shows", @"Show search result header");
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self shouldDisplayMostSearchedShows]) {
        SRGShow *show = self.items[indexPath.row];
        SectionViewController *showViewController = [SectionViewController showViewControllerFor:show];
        [self.navigationController pushViewController:showViewController animated:YES];
        
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.value = show.URN;
        labels.type = AnalyticsTypeActionDisplayShow;
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSearchTeaserOpen labels:labels];
    }
    else if ([self isDisplayingMediasInSection:indexPath.section]) {
        SRGMedia *media = self.items[indexPath.row];
        [self play_presentMediaPlayerWithMedia:media position:nil airPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
        
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.value = media.URN;
        labels.type = AnalyticsTypeActionPlayMedia;
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSearchOpen labels:labels];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if ([self shouldDisplayMostSearchedShows]) {
        return UIEdgeInsetsZero;
    }
    else {
        return UIEdgeInsetsMake(0.f, 2 * LayoutMargin, 0.f, 2 * LayoutMargin);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    if ([self shouldDisplayMostSearchedShows]) {
        return 0.f;
    }
    else {
        return LayoutMargin;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    if ([self shouldDisplayMostSearchedShows]) {
        return 0.f;
    }
    else {
        return LayoutMargin;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self shouldDisplayMostSearchedShows]) {
        UIFontMetrics *fontMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle2];
        return CGSizeMake(CGRectGetWidth(collectionView.frame) - 4 * LayoutMargin, [fontMetrics scaledValueForValue:50.f]);
    }
    else if ([self isLoadingObjectsInSection:indexPath.section]) {
        return CGSizeMake(CGRectGetWidth(collectionView.frame), 200.f);
    }
    else if ([self isDisplayingMediasInSection:indexPath.section]) {
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
            CGSize size = [[MediaCellSize fullWidth] constrainedBy:collectionView];
            return CGSizeMake(size.width - 4 * LayoutMargin, size.height);
        }
        else {
            return [[MediaCellSize gridWithLayoutWidth:CGRectGetWidth(collectionView.frame) - 4 * LayoutMargin spacing:collectionViewLayout.minimumInteritemSpacing minimumNumberOfColumns:1] constrainedBy:collectionView];
        }
    }
    // Search show list
    else {
        // Small margin to avoid overlap with the horizontal scrolling indicator
        CGFloat height = [[ShowCellSize swimlane] constrainedBy:collectionView].height + 15.f;
        return CGSizeMake(CGRectGetWidth(collectionView.frame), height);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if ([self isDisplayingMostSearchedShows] || [self isDisplayingObjectsInSection:section]) {
        return CGSizeMake(CGRectGetWidth(collectionView.frame), 44.f);
    }
    else {
        return CGSizeZero;
    }
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point
{
    if ([self shouldDisplayMostSearchedShows] || [self isLoadingObjectsInSection:indexPath.section]) {
        return nil;
    }
    else if ([self isDisplayingMediasInSection:indexPath.section]) {
        return [super collectionView:collectionView contextMenuConfigurationForItemAtIndexPath:indexPath point:point];
    }
    else {
        return nil;
    }
}

#pragma mark UISearchBarDelegate protocol

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchController.searchBar resignFirstResponder];
}

// `UISearchController` header documents the `-updateSearchResultsForSearchController:` to be called when the scope
// changes, but in practice this does not work. The generated documentation does not say so and is therefore correct,
// see https://developer.apple.com/documentation/uikit/uisearchresultsupdating/1618658-updatesearchresultsforsearchcont?language=objc
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self updateSearchResultsForSearchController:self.searchController];
}

- (void)showSettings:(id)sender
{
    [self.searchController.searchBar resignFirstResponder];
    
    SearchSettingsViewController *searchSettingsViewController = [[SearchSettingsViewController alloc] initWithQuery:self.query settings:self.settings ?: SearchSettingsViewController.defaultSettings];
    searchSettingsViewController.delegate = self;
    
    UIColor *backgroundColor = (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) ? UIColor.play_popoverGrayBackgroundColor : nil;
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:searchSettingsViewController
                                                                                                tintColor:UIColor.whiteColor
                                                                                          backgroundColor:backgroundColor
                                                                                                separator:YES
                                                                                           statusBarStyle:UIStatusBarStyleLightContent];
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverPresentationController = navigationController.popoverPresentationController;
    popoverPresentationController.backgroundColor = UIColor.play_popoverGrayBackgroundColor;
    popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    popoverPresentationController.barButtonItem = self.filtersBarButtonItem;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark UISearchResultsUpdating protocol

// This method is also triggered when the search bar gets or loses the focus. We only perform a search when needed to
// avoid unnecessary refreshes.
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    // Perform the search with a delay to avoid triggering several search requests if updates are made in a row
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(search) object:nil];
    
    UISearchBar *searchBar = searchController.searchBar;
    NSString *query = searchBar.text;
    
    // Add delay when typing, i.e. when the query changes
    if (! [query isEqualToString:self.query]) {
        // No delay when the search text is too small. This also covers the case where the user clears the search criterium
        // with the clear button
        static NSTimeInterval kTypingSpeedThreshold = 0.3;
        NSTimeInterval delay = (searchBar.text.length == 0) ? 0. : kTypingSpeedThreshold;
        [self performSelector:@selector(search) withObject:nil afterDelay:delay inModes:@[ NSRunLoopCommonModes ]];
    }
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView.dragging && ! scrollView.decelerating) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self.collectionView reloadData];
}

@end
