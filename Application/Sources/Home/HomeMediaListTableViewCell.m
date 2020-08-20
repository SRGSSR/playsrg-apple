//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeMediaListTableViewCell.h"

#import "ApplicationSettings.h"
#import "HomeLiveMediaCollectionViewCell.h"
#import "HomeMediaCollectionHeaderView.h"
#import "HomeMediaCollectionViewCell.h"
#import "Layout.h"
#import "MediaPlayerViewController.h"
#import "SRGModule+PlaySRG.h"
#import "SwimlaneCollectionViewLayout.h"
#import "UIColor+PlaySRG.h"
#import "UIView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import SRGAppearance;

static BOOL HomeSectionHasLiveContent(HomeSection homeSection)
{
    return homeSection == HomeSectionTVLive || homeSection == HomeSectionRadioLive || homeSection == HomeSectionRadioLiveSatellite
        || homeSection == HomeSectionTVLiveCenter || homeSection == HomeSectionTVScheduledLivestreams;
}

@interface HomeMediaListTableViewCell ()

@property (nonatomic, weak) UIView *moduleBackgroundView;
@property (nonatomic, weak) UIView *wrapperView;
@property (nonatomic, weak) UICollectionView *collectionView;

@end

@implementation HomeMediaListTableViewCell

#pragma mark Class overrides

+ (CGFloat)heightForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds featured:(BOOL)featured
{
    return [self itemSizeForHomeSectionInfo:homeSectionInfo bounds:bounds featured:featured].height;
}

#pragma mark Class methods

+ (CGSize)itemSizeForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds featured:(BOOL)featured
{
    CGFloat itemWidth = 0.f;
    
    if (featured) {
        itemWidth = LayoutCollectionItemFeaturedWidth(CGRectGetWidth(bounds));
    }
    else {
        itemWidth = LayoutCollectionViewCellStandardWidth;
    }
    
    if (HomeSectionHasLiveContent(homeSectionInfo.homeSection)) {
        return LayoutLiveMediaStandardCollectionItemSize(itemWidth);
    }
    else {
        return LayoutMediaStandardCollectionItemSize(itemWidth, featured);
    }
}

#pragma mark Object lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = UIColor.clearColor;
        self.selectedBackgroundView.backgroundColor = UIColor.clearColor;
        
        UIView *moduleBackgroundView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        moduleBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:moduleBackgroundView];
        self.moduleBackgroundView = moduleBackgroundView;
        
        [NSLayoutConstraint activateConstraints:@[
            [moduleBackgroundView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [moduleBackgroundView.heightAnchor constraintEqualToConstant:75.f],
            [moduleBackgroundView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [moduleBackgroundView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
        ]];
        
        UIView *wrapperView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        wrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:wrapperView];
        self.wrapperView = wrapperView;
        
        SwimlaneCollectionViewLayout *collectionViewLayout = [[SwimlaneCollectionViewLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        collectionViewLayout.minimumLineSpacing = LayoutStandardMargin;
        collectionViewLayout.minimumInteritemSpacing = LayoutStandardMargin;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:wrapperView.bounds collectionViewLayout:collectionViewLayout];
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
        [wrapperView addSubview:collectionView];
        self.collectionView = collectionView;
        
        // Remark: The collection view is nested in a dummy view to workaround an accessibility bug
        //         See https://stackoverflow.com/a/38798448/760435
        wrapperView.accessibilityElements = @[collectionView];
        
        NSString *mediaCellIdentifier = NSStringFromClass(HomeMediaCollectionViewCell.class);
        UINib *mediaCellNib = [UINib nibWithNibName:mediaCellIdentifier bundle:nil];
        [collectionView registerNib:mediaCellNib forCellWithReuseIdentifier:mediaCellIdentifier];
        
        NSString *liveMediaCellIdentifier = NSStringFromClass(HomeLiveMediaCollectionViewCell.class);
        UINib *liveMediaCellNib = [UINib nibWithNibName:liveMediaCellIdentifier bundle:nil];
        [collectionView registerNib:liveMediaCellNib forCellWithReuseIdentifier:liveMediaCellIdentifier];
        
        NSString *headerViewIdentifier = NSStringFromClass(HomeMediaCollectionHeaderView.class);
        UINib *headerNib = [UINib nibWithNibName:headerViewIdentifier bundle:nil];
        [collectionView registerNib:headerNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerViewIdentifier];
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

#pragma mark Getters and setters

- (void)setHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo featured:(BOOL)featured
{
    [super setHomeSectionInfo:homeSectionInfo featured:featured];
    
    self.moduleBackgroundView.backgroundColor = homeSectionInfo.module.play_backgroundColor;
    
    if (homeSectionInfo) {
        // Restore position in rows when scrolling vertically and returning to a previously scrolled row
        CGPoint contentOffset = [self.collectionView.collectionViewLayout targetContentOffsetForProposedContentOffset:homeSectionInfo.contentOffset];
        [self.collectionView setContentOffset:contentOffset animated:NO];
    }
    self.collectionView.scrollEnabled = (homeSectionInfo.items.count != 0);
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return ! [self isEmpty] ? self.homeSectionInfo.items.count : 10 /* Display 10 placeholders */;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (HomeSectionHasLiveContent(self.homeSectionInfo.homeSection)) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(HomeLiveMediaCollectionViewCell.class) forIndexPath:indexPath];
    }
    else {
        return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(HomeMediaCollectionViewCell.class) forIndexPath:indexPath];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSAssert([kind isEqualToString:UICollectionElementKindSectionHeader], @"Only section headers are currently used");
    
    HomeMediaCollectionHeaderView *homeMediaCollectionHeaderView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                      withReuseIdentifier:NSStringFromClass(HomeMediaCollectionHeaderView.class)
                                                                                                             forIndexPath:indexPath];
    homeMediaCollectionHeaderView.leftEdgeInset = LayoutStandardMargin;
    return homeMediaCollectionHeaderView;
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGMedia *media = ! [self isEmpty] ? self.homeSectionInfo.items[indexPath.row] : nil;
    
    if ([cell isKindOfClass:HomeLiveMediaCollectionViewCell.class]) {
        HomeLiveMediaCollectionViewCell *liveMediaCell = (HomeLiveMediaCollectionViewCell *)cell;
        liveMediaCell.media = media;
    }
    else {
        HomeMediaCollectionViewCell *mediaCell = (HomeMediaCollectionViewCell *)cell;
        [mediaCell setMedia:media module:self.homeSectionInfo.module featured:self.featured];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([view isKindOfClass:HomeMediaCollectionHeaderView.class]) {
        HomeMediaCollectionHeaderView *headerView = (HomeMediaCollectionHeaderView *)view;
        [headerView setHomeSectionInfo:self.homeSectionInfo featured:self.featured];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (! [self isEmpty]) {
        SRGMedia *media = self.homeSectionInfo.items[indexPath.row];
        [self.play_nearestViewController play_presentMediaPlayerWithMedia:media position:nil airPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [HomeMediaListTableViewCell itemSizeForHomeSectionInfo:self.homeSectionInfo bounds:collectionView.bounds featured:self.featured];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (self.homeSectionInfo.module || (self.homeSectionInfo.topic && ! ApplicationConfiguration.sharedApplicationConfiguration.topicHomeHeadersHidden)) {
        CGSize size = [self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        size.width += LayoutStandardMargin;
        return size;
    }
    else {
        return CGSizeZero;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (self.homeSectionInfo.module) {
        return UIEdgeInsetsMake(0.f, collectionViewLayout.minimumInteritemSpacing, 0.f, LayoutStandardMargin);
    }
    else {
        return UIEdgeInsetsMake(0.f, LayoutStandardMargin, 0.f, LayoutStandardMargin);
    }
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.homeSectionInfo.contentOffset = scrollView.contentOffset;
}

@end
