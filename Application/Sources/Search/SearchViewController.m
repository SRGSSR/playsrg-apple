//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchViewController.h"

#import "SearchResultsViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <Masonry/Masonry.h>
#import <SRGAnalytics/SRGAnalytics.h>

const NSInteger SearchViewControllerSearchTextMinimumLength = 3;

@interface SearchViewController () <SearchResultsViewControllerDelegate>

@property (nonatomic, weak) UISearchBar *searchBar;

@end

@implementation SearchViewController

#pragma mark Object lifecycle

- (instancetype)initWithPreferredSearchOption:(SearchOption)searchOption
{
    NSArray<NSNumber *> *searchOptions = ApplicationConfiguration.sharedApplicationConfiguration.searchOptions;
    NSAssert(searchOptions.count != 0, @"Search options must be available");
    
    if (! [searchOptions containsObject:@(searchOption)]) {
        if (searchOption == SearchOptionTVShows && [searchOptions containsObject:@(SearchOptionVideos)]) {
            searchOption = SearchOptionVideos;
        }
        else if (searchOption == SearchOptionRadioShows && [searchOptions containsObject:@(SearchOptionAudios)]) {
            searchOption = SearchOptionAudios;
        }
        else {
            searchOption = searchOptions.firstObject.integerValue;
        }
    }
    
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    for (NSNumber *searchOption in searchOptions) {
        SearchResultsViewController *searchResultsViewController = [[SearchResultsViewController alloc] initWithSearchOption:searchOption.integerValue];
        [viewControllers addObject:searchResultsViewController];
    }
    
    NSUInteger index = [searchOptions indexOfObject:@(searchOption)];
    return [super initWithViewControllers:[viewControllers copy] initialPage:index];
}

- (instancetype)init
{
    return [self initWithPreferredSearchOption:SearchOptionUnknown];
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
    
    // Not in -init since made on self and the view controller list is created earlier in -init
    for (SearchResultsViewController *searchResultsViewController in self.viewControllers) {
        searchResultsViewController.delegate = self;
    }
    
    self.view.backgroundColor = UIColor.play_blackColor;
    
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

#pragma mark Helpers

- (void)sendAnalytics
{
    NSString *searchText = self.searchBar.text;
    if (searchText.length >= SearchViewControllerSearchTextMinimumLength) {
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.value = self.searchBar.text;
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

#pragma mark SearchResultsViewControllerDelegate protocol

- (void)searchResultsViewControllerWasDragged:(SearchResultsViewController *)searchResultsViewController
{
    [self.searchBar resignFirstResponder];
}

#pragma mark UISearchBarDelegate protocol

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    for (SearchResultsViewController *searchResultsViewController in self.viewControllers) {
        [searchResultsViewController updateWithSearchText:searchText];
    }
    
    // Add a large delay to avoid sending search events when the user is typing fast
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendAnalytics) object:nil];
    [self performSelector:@selector(sendAnalytics) withObject:nil afterDelay:3.];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
}

#pragma mark Actions

- (void)close:(id)sender
{
    NSAssert(self.closeBlock, @"Close must only be available if a close block has been defined");
    self.closeBlock();
}

@end
