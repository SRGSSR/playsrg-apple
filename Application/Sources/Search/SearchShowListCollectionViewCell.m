//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchShowListCollectionViewCell.h"

#import "AnalyticsConstants.h"
#import "ShowCollectionViewCell.h"
#import "ShowViewController.h"

#import <CoconutKit/CoconutKit.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

@interface SearchShowListCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

@implementation SearchShowListCollectionViewCell

#pragma mark Class methods

+ (CGSize)itemSize
{
    static NSDictionary<NSString *, NSNumber *> *s_textHeights;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_textHeights = @{ UIContentSizeCategoryExtraSmall : @26,
                           UIContentSizeCategorySmall : @26,
                           UIContentSizeCategoryMedium : @27,
                           UIContentSizeCategoryLarge : @29,
                           UIContentSizeCategoryExtraLarge : @31,
                           UIContentSizeCategoryExtraExtraLarge : @34,
                           UIContentSizeCategoryExtraExtraExtraLarge : @36,
                           UIContentSizeCategoryAccessibilityMedium : @36,
                           UIContentSizeCategoryAccessibilityLarge : @36,
                           UIContentSizeCategoryAccessibilityExtraLarge : @36,
                           UIContentSizeCategoryAccessibilityExtraExtraLarge : @36,
                           UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @36 };
    });
    
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    CGFloat minTextHeight = s_textHeights[contentSizeCategory].floatValue;
    
    static CGFloat kItemWidth = 300.f;
    return CGSizeMake(kItemWidth, ceilf(kItemWidth * 9.f / 16.f + minTextHeight));
}

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
        
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.contentView.bounds collectionViewLayout:collectionViewLayout];
        collectionView.backgroundColor = UIColor.clearColor;
        collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.directionalLockEnabled = YES;
        // Important. If > 1 view on-screen is found on iPhone with this property enabled, none will scroll to top
        collectionView.scrollsToTop = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [self.contentView addSubview:collectionView];
        self.collectionView = collectionView;
        
        NSString *showCellIdentifier = NSStringFromClass(ShowCollectionViewCell.class);
        UINib *showCellNib = [UINib nibWithNibName:showCellIdentifier bundle:nil];
        [collectionView registerNib:showCellNib forCellWithReuseIdentifier:showCellIdentifier];
    }
    return self;
}

#pragma mark Getters and setters

- (void)setShows:(NSArray *)shows
{
    NSArray<SRGShow *> *previousShows = _shows;
    _shows = shows;
    
    [self.collectionView reloadData];
    
    // When a cell is reused to display a different show list, return to offset zero
    if (! [previousShows isEqualToArray:shows]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView setContentOffset:CGPointZero animated:NO];
        });
    }
}

#pragma mark Overrides

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.shows = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.shows.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ShowCollectionViewCell.class) forIndexPath:indexPath];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(ShowCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setShow:self.shows[indexPath.row] featured:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGShow *show = self.shows[indexPath.row];
    ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:show fromPushNotification:NO];
    [self.nearestViewController.navigationController pushViewController:showViewController animated:YES];
    
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.value = show.URN;
    labels.type = AnalyticsTypeActionDisplayShow;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSearchOpen labels:labels];
    
    [[SRGDataProvider.currentDataProvider increaseSearchResultsViewCountForShow:show withCompletionBlock:^(SRGShowStatisticsOverview * _Nullable showStatisticsOverview, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        // Nothing
    }] resume];
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.class.itemSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0.f, 10.f, 0.f, 10.f);
}

@end
