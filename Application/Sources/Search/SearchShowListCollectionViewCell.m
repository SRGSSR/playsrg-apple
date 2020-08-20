//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchShowListCollectionViewCell.h"

#import "AnalyticsConstants.h"
#import "Layout.h"
#import "ShowCollectionViewCell.h"
#import "ShowViewController.h"
#import "SwimlaneCollectionViewLayout.h"
#import "UIView+PlaySRG.h"

@import SRGAnalytics;
@import SRGAppearance;

// Small margin to avoid overlap with the horizontal scrolling indicator
static const CGFloat kBottomInset = 15.f;

@interface SearchShowListCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

@implementation SearchShowListCollectionViewCell

#pragma mark Class methods

+ (CGFloat)height
{
    return self.itemSize.height + kBottomInset;
}

+ (CGSize)itemSize
{
    return LayoutShowStandardCollectionItemSize(300.f, NO);
}

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
        
        SwimlaneCollectionViewLayout *collectionViewLayout = [[SwimlaneCollectionViewLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        collectionViewLayout.minimumLineSpacing = LayoutStandardMargin;
        collectionViewLayout.minimumInteritemSpacing = LayoutStandardMargin;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.contentView.bounds collectionViewLayout:collectionViewLayout];
        collectionView.backgroundColor = UIColor.clearColor;
        collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.directionalLockEnabled = YES;
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
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
    [self.play_nearestViewController.navigationController pushViewController:showViewController animated:YES];
    
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
    return UIEdgeInsetsMake(0.f, LayoutStandardMargin, kBottomInset, LayoutStandardMargin);
}

@end
