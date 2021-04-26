//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ShowsViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "ApplicationSection.h"
#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "Play-Swift-Bridge.h"
#import "ShowViewController.h"
#import "TranslucentTitleHeaderView.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <BDKCollectionIndexView/BDKCollectionIndexView.h>

@import libextobjc;
@import SRGAppearance;

@interface ShowsViewController () {
@private
    NSInteger _previousAccessibilityHeadingSection;
}

@property (nonatomic) RadioChannel *radioChannel;
@property (nonatomic) NSString *initialAlphabeticalIndex;

@property (nonatomic) NSArray<NSString *> *indexLetters;
@property (nonatomic) NSDictionary<NSString *, NSArray<SRGShow *> *> *showsAlphabeticalMap;

@property (nonatomic, weak) BDKCollectionIndexView *collectionIndexView;

@property (nonatomic) UISelectionFeedbackGenerator *selectionFeedbackGenerator API_AVAILABLE(ios(10.0));

@end

@implementation ShowsViewController

#pragma mark Object lifecycle

- (instancetype)initWithRadioChannel:(RadioChannel *)radioChannel alphabeticalIndex:(NSString *)alphabeticalIndex
{
    if (self = [super init]) {
        self.radioChannel = radioChannel;
        self.initialAlphabeticalIndex = alphabeticalIndex;
        self.emptyCollectionImage = [UIImage imageNamed:@"media-90"];
        self.selectionFeedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        
        _previousAccessibilityHeadingSection = -1;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithRadioChannel:nil alphabeticalIndex:nil];
}

#pragma mark Getters and setters

- (NSString *)title
{
    return TitleForApplicationSection(ApplicationSectionShowAZ);
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.play_blackColor;
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    collectionViewLayout.minimumInteritemSpacing = LayoutStandardMargin;
    collectionViewLayout.minimumLineSpacing = LayoutStandardMargin;
    collectionViewLayout.sectionHeadersPinToVisibleBounds = YES;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:view.bounds collectionViewLayout:collectionViewLayout];
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    collectionView.showsVerticalScrollIndicator = NO;      // As in Contacts, no need for scroll indicators when an index is displayed
    collectionView.alwaysBounceVertical = YES;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:collectionView];
    self.collectionView = collectionView;
    
    BDKCollectionIndexView *collectionIndexView = [[BDKCollectionIndexView alloc] initWithFrame:CGRectZero indexTitles:nil];
    collectionIndexView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionIndexView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.4f];
    collectionIndexView.tintColor = UIColor.play_lightGrayColor;
    collectionIndexView.alpha = 1.f;
    collectionIndexView.hidden = YES;
    [collectionIndexView addTarget:self action:@selector(collectionIndexChanged:) forControlEvents:UIControlEventValueChanged];
    [view addSubview:collectionIndexView];
    self.collectionIndexView = collectionIndexView;
    
    NSString *headerIdentifier = NSStringFromClass(TranslucentTitleHeaderView.class);
    UINib *headerNib = [UINib nibWithNibName:headerIdentifier bundle:nil];
    [collectionView registerNib:headerNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerIdentifier];
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionIndexView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.collectionIndexView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [self.collectionIndexView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor],
        [self.collectionIndexView.widthAnchor constraintEqualToConstant:28.f]
    ]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // UICollectionView loads its content lazily and headers might therefore not visible and accessible when navigating
    // in headings accessibility mode. To solve this issue, we follow the focus and scroll the collection automatically
    // to reveal the last section item
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityElementFocused:)
                                               name:UIAccessibilityElementFocusedNotification
                                             object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIAccessibilityElementFocusedNotification
                                                object:nil];
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

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    SRGVendor vendor = ApplicationConfiguration.sharedApplicationConfiguration.vendor;
    
    // Since we need to display the A-Z index, all shows need to be loaded. We therefore do not use the native page
    // support but load all the shows at once
    if (self.radioChannel) {
        SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider radioShowsForVendor:vendor channelUid:self.radioChannel.uid withCompletionBlock:completionHandler] requestWithPageSize:SRGDataProviderUnlimitedPageSize] requestWithPage:page];
        [requestQueue addRequest:request resume:YES];
    }
    else {
        SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider tvShowsForVendor:vendor withCompletionBlock:completionHandler] requestWithPageSize:SRGDataProviderUnlimitedPageSize] requestWithPage:page];
        [requestQueue addRequest:request resume:YES];
    }
}

- (void)refreshDidFinishWithError:(NSError *)error
{
    // Separate all shows according to their first letter (beware of special characters and emojis)
    NSMutableDictionary<NSString *, NSMutableArray<SRGShow *> *> *showsAlphabeticalMap = [NSMutableDictionary dictionary];
    [self.items enumerateObjectsUsingBlock:^(SRGShow *  _Nonnull show, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableString *firstLetter = [show.title substringToIndex:1].uppercaseString.mutableCopy;
        if (!firstLetter) {
            return;
        }
        
        // Remove accents / diacritics and extract the first char (for wide chars / emoji support)
        CFStringTransform((__bridge CFMutableStringRef)firstLetter, NULL, kCFStringTransformStripCombiningMarks, NO);
        unichar firstChar = [firstLetter characterAtIndex:0];
        if (!isalpha(firstChar)) {
            firstChar = '#';
        }
        
        NSString *indexLetter = [NSString stringWithCharacters:&firstChar length:1];
        
        NSMutableArray *showsForIndexLetter = showsAlphabeticalMap[indexLetter];
        if (!showsForIndexLetter) {
            showsForIndexLetter = [NSMutableArray array];
            showsAlphabeticalMap[indexLetter] = showsForIndexLetter;
        }
        [showsForIndexLetter addObject:show];
    }];
    
    self.showsAlphabeticalMap = showsAlphabeticalMap.copy;
    self.indexLetters = [showsAlphabeticalMap.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    self.collectionIndexView.indexTitles = self.indexLetters;
    self.collectionIndexView.hidden = (self.indexLetters.count == 0);
    
    // Call last to continue with the reload process, based on the sorted data
    [super refreshDidFinishWithError:error];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.indexLetters.count > 0 && self.initialAlphabeticalIndex) {
            NSUInteger sectionIndex = [self.indexLetters indexOfObject:self.initialAlphabeticalIndex.uppercaseString];
            if (sectionIndex != NSNotFound) {
                [self scrollToSectionWithIndex:sectionIndex animated:NO];
            }
            self.initialAlphabeticalIndex = nil;
        }
    });
}

#pragma mark Scrolling

- (void)scrollToSectionWithIndex:(NSUInteger)index animated:(BOOL)animated
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:index];
    
    // -scrollToItemAtIndexPath:atScrollPosition:animated: doesn't take care of the sticky section header and transparent navigation bar
    CGRect sectionHeaderFrame = [self.collectionView layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath].frame;
    CGRect itemFrame = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath].frame;
    
    CGFloat contentInsetTop = ContentInsetsForScrollView(self.collectionView).top;
    CGFloat sectionHeaderHeight = CGRectGetHeight(sectionHeaderFrame);
    CGFloat newContentOffsetY = fminf(CGRectGetMinY(itemFrame) - sectionHeaderHeight - contentInsetTop,
                                      self.collectionView.contentSize.height - CGRectGetHeight(self.collectionView.frame));
    [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, newContentOffsetY) animated:animated];
}

#pragma mark Index

- (void)setIndexHidden:(BOOL)hidden animated:(BOOL)animated
{
    void (^animations)(void) = ^{
        self.collectionIndexView.alpha = hidden ? 0.f : 1.f;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    }
    else {
        animations();
    }
}

- (void)automaticallyShowIndexAnimated
{
    [self setIndexHidden:NO animated:YES];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.indexLetters.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSString *indexLetter = self.indexLetters[section];
    return self.showsAlphabeticalMap[indexLetter].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *indexLetter = self.indexLetters[indexPath.section];
    SRGShow *show = self.showsAlphabeticalMap[indexLetter][indexPath.row];
    return [collectionView showCellFor:indexPath show:show];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                  withReuseIdentifier:NSStringFromClass(TranslucentTitleHeaderView.class)
                                                         forIndexPath:indexPath];
    }
    else {
        return [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([view isKindOfClass:TranslucentTitleHeaderView.class]) {
        TranslucentTitleHeaderView *headerView = (TranslucentTitleHeaderView *)view;
        headerView.title = self.indexLetters[indexPath.section];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *indexLetter = self.indexLetters[indexPath.section];
    SRGShow *show = self.showsAlphabeticalMap[indexLetter][indexPath.row];
    
    ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:show fromPushNotification:NO];
    [self.navigationController pushViewController:showViewController animated:YES];
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(LayoutStandardMargin, LayoutStandardMargin, LayoutStandardMargin, LayoutStandardMargin);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat itemWidth = LayoutCollectionItemOptimalWidth(LayoutStandardCellWidth, CGRectGetWidth(collectionView.frame), LayoutStandardSectionContentInsets.leading, LayoutStandardSectionContentInsets.trailing, collectionViewLayout.minimumInteritemSpacing);
    return LayoutCollectionItemSize(itemWidth, LayoutCollectionItemTypeShowSwimlaneOrGrid, self.traitCollection.horizontalSizeClass);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(CGRectGetWidth(collectionView.frame) - 2 * LayoutStandardMargin, 44.f);
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitleShowsAZ;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    if (self.radioChannel) {
        return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelAudio, self.radioChannel.name ];
    }
    else {
        return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelVideo ];
    }
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(automaticallyShowIndexAnimated) object:nil];
    [self setIndexHidden:YES animated:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(automaticallyShowIndexAnimated) object:nil];
        [self performSelector:@selector(automaticallyShowIndexAnimated) withObject:nil afterDelay:0.7 inModes:@[ NSRunLoopCommonModes ]];
    }
    else {
        [self setIndexHidden:NO animated:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(automaticallyShowIndexAnimated) object:nil];
    [self setIndexHidden:NO animated:YES];
}

#pragma mark Actions

- (IBAction)collectionIndexChanged:(id)sender
{
    NSAssert([sender isKindOfClass:BDKCollectionIndexView.class], @"Expect a collection index");
    
    [self.selectionFeedbackGenerator selectionChanged];
    
    BDKCollectionIndexView *collectionIndexView = sender;
    [self scrollToSectionWithIndex:collectionIndexView.currentIndex animated:NO];
}

#pragma mark Notifications

- (void)accessibilityElementFocused:(NSNotification *)notification
{
    id element = notification.userInfo[UIAccessibilityFocusedElementKey];
    
    // Filter only focus notifications related to the receiver
    if ([element isKindOfClass:TranslucentTitleHeaderView.class] && [element isDescendantOfView:self.view]) {
        TranslucentTitleHeaderView *headerView = element;
        NSParameterAssert(headerView.title);
        
        NSInteger section = [self.indexLetters indexOfObject:headerView.title];
        
        NSIndexPath *indexPath = nil;
        
        // Moving downwards. Go to section end
        if (section > _previousAccessibilityHeadingSection) {
            NSUInteger numberOfItems = [self collectionView:self.collectionView numberOfItemsInSection:section];
            indexPath = [NSIndexPath indexPathForRow:numberOfItems - 1 inSection:section];
        }
        // Moving upwards. Go to section beginning
        else {
            indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        }
        
        _previousAccessibilityHeadingSection = section;
        
        // Center the item (works in both directions, and top or bottom would potentially not scroll anything if not needed)
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
    }
    else {
        _previousAccessibilityHeadingSection = -1;
    }
}

@end
