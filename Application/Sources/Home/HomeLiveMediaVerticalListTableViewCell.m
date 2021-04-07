//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeLiveMediaVerticalListTableViewCell.h"

#import "ApplicationSettings.h"
#import "HomeLiveMediaCollectionViewCell.h"
#import "Layout.h"
#import "UIView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import SRGAppearance;

@interface HomeLiveMediaVerticalListTableViewCell ()

@property (nonatomic, weak) UIView *wrapperView;
@property (nonatomic, weak) UICollectionView *collectionView;

@end

@implementation HomeLiveMediaVerticalListTableViewCell

#pragma mark Class overrides

+ (CGFloat)heightForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds featured:(BOOL)featured
{
    CGSize itemSize = [self itemSizeForHomeSectionInfo:homeSectionInfo bounds:bounds];
    NSInteger numberOfItemsPerRow = floorf((CGRectGetWidth(bounds) - LayoutStandardMargin) / (itemSize.width + LayoutStandardMargin));
    NSInteger numberOfItems = (homeSectionInfo.items.count != 0) ? homeSectionInfo.items.count : 4;
    NSInteger numberOfLines = MAX(ceilf((float)numberOfItems / numberOfItemsPerRow), 1);
    return itemSize.height * numberOfLines + (numberOfLines - 1) * LayoutStandardMargin;
}

#pragma mark Class methods

+ (CGSize)itemSizeForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds
{
    CGFloat approximateWidth = (CGRectGetWidth(bounds) < 1000.f) ? LayoutStandardCellWidth : 275.f;
    CGFloat itemWidth = LayoutCollectionItemOptimalWidth(approximateWidth, CGRectGetWidth(bounds), LayoutStandardMargin, LayoutStandardMargin, LayoutStandardMargin);
    return LayoutLiveMediaStandardCollectionItemSize(itemWidth);
}

#pragma mark Object lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = UIColor.clearColor;
        self.selectedBackgroundView.backgroundColor = UIColor.clearColor;
        
        UIView *wrapperView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        wrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:wrapperView];
        self.wrapperView = wrapperView;
        
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        collectionViewLayout.minimumLineSpacing = LayoutStandardMargin;
        collectionViewLayout.minimumInteritemSpacing = LayoutStandardMargin;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:wrapperView.bounds collectionViewLayout:collectionViewLayout];
        collectionView.backgroundColor = UIColor.clearColor;
        collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        // Important. If > 1 view on-screen is found on iPhone with this property enabled, none will scroll to top
        collectionView.scrollsToTop = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [wrapperView addSubview:collectionView];
        self.collectionView = collectionView;
        
        // Remark: The collection view is nested in a dummy view to workaround an accessibility bug
        //         See https://stackoverflow.com/a/38798448/760435
        wrapperView.accessibilityElements = @[collectionView];
        
        NSString *mediaCellIdentifier = NSStringFromClass(HomeLiveMediaCollectionViewCell.class);
        UINib *mediaCellNib = [UINib nibWithNibName:mediaCellIdentifier bundle:nil];
        [collectionView registerNib:mediaCellNib forCellWithReuseIdentifier:mediaCellIdentifier];
    }
    return self;
}

#pragma mark Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)reloadData
{
    [super reloadData];
    
    [self.collectionView reloadData];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return ! [self isEmpty] ? self.homeSectionInfo.items.count : 4;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(HomeLiveMediaCollectionViewCell.class) forIndexPath:indexPath];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(HomeLiveMediaCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    cell.media = ! [self isEmpty] ? self.homeSectionInfo.items[indexPath.row] : nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (! [self isEmpty]) {
        SRGMedia *media = self.homeSectionInfo.items[indexPath.row];
        [self.play_nearestViewController play_presentMediaPlayerWithMedia:media position:nil airPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0.f, LayoutStandardMargin, 0.f, LayoutStandardMargin);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [HomeLiveMediaVerticalListTableViewCell itemSizeForHomeSectionInfo:self.homeSectionInfo bounds:collectionView.bounds];
}

@end
