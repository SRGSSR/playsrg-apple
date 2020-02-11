//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeMediaListTableViewCell.h"

#import "HomeMediaCollectionHeaderView.h"
#import "HomeMediaCollectionViewCell.h"
#import "MediaPlayerViewController.h"
#import "SRGBaseTopic+PlaySRG.h"
#import "UICollectionView+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <CoconutKit/CoconutKit.h>
#import <SRGAppearance/SRGAppearance.h>

static const CGFloat HomeStandardMargin = 10.f;

@interface HomeMediaListTableViewCell ()

@property (nonatomic, weak) IBOutlet UIView *wrapperView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

@implementation HomeMediaListTableViewCell

#pragma mark Overrides

+ (CGFloat)heightForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds featured:(BOOL)featured
{
    return [self itemSizeForHomeSectionInfo:homeSectionInfo bounds:bounds featured:featured].height;
}

+ (CGSize)itemSizeForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds featured:(BOOL)featured
{
    CGFloat itemWidth = 0.f;
    
    if (featured) {
        // Ensure cells never fill the entire width of the parent, so that the fact that content can be scrolled
        // is always obvious to the user
        static const CGFloat kHorizontalFillRatio = 0.9f;
        
        // Do not make cells unnecessarily large, especially on iPhone Plus
        UITraitCollection *traitCollection = UIApplication.sharedApplication.keyWindow.traitCollection;
        CGFloat maxWidth = (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) ? 300.f : 650.f;
        
        itemWidth = MIN(CGRectGetWidth(bounds) * kHorizontalFillRatio, maxWidth);
    }
    else {
        itemWidth = 210.f;
    }
    
    // Adjust height depending on font size settings. First section cells are different and require specific values
    static NSDictionary<NSString *, NSNumber *> *s_featuredTextHeigths;
    static NSDictionary<NSString *, NSNumber *> *s_standardTextHeigths;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_featuredTextHeigths = @{ UIContentSizeCategoryExtraSmall : @79,
                                   UIContentSizeCategorySmall : @81,
                                   UIContentSizeCategoryMedium : @84,
                                   UIContentSizeCategoryLarge : @89,
                                   UIContentSizeCategoryExtraLarge : @94,
                                   UIContentSizeCategoryExtraExtraLarge : @102,
                                   UIContentSizeCategoryExtraExtraExtraLarge : @108,
                                   UIContentSizeCategoryAccessibilityMedium : @108,
                                   UIContentSizeCategoryAccessibilityLarge : @108,
                                   UIContentSizeCategoryAccessibilityExtraLarge : @108,
                                   UIContentSizeCategoryAccessibilityExtraExtraLarge : @108,
                                   UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @108 };
        
        s_standardTextHeigths = @{ UIContentSizeCategoryExtraSmall : @63,
                                   UIContentSizeCategorySmall : @65,
                                   UIContentSizeCategoryMedium : @67,
                                   UIContentSizeCategoryLarge : @70,
                                   UIContentSizeCategoryExtraLarge : @75,
                                   UIContentSizeCategoryExtraExtraLarge : @82,
                                   UIContentSizeCategoryExtraExtraExtraLarge : @90,
                                   UIContentSizeCategoryAccessibilityMedium : @90,
                                   UIContentSizeCategoryAccessibilityLarge : @90,
                                   UIContentSizeCategoryAccessibilityExtraLarge : @90,
                                   UIContentSizeCategoryAccessibilityExtraExtraLarge : @90,
                                   UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @90 };
    });
    
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    CGFloat minTextHeight = featured ? s_featuredTextHeigths[contentSizeCategory].floatValue : s_standardTextHeigths[contentSizeCategory].floatValue;
    return CGSizeMake(itemWidth, ceilf(itemWidth * 9.f / 16.f + minTextHeight));
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    self.selectedBackgroundView.backgroundColor = UIColor.clearColor;
    
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.collectionView.alwaysBounceHorizontal = YES;
    self.collectionView.directionalLockEnabled = YES;
    // Important. If > 1 view on-screen is found on iPhone with this property enabled, none will scroll to top
    self.collectionView.scrollsToTop = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    // Remark: The collection view is nested in a dummy view to workaround an accessibility bug
    //         See https://stackoverflow.com/a/38798448/760435
    self.wrapperView.accessibilityElements = @[self.collectionView];
    
    NSString *mediaCellIdentifier = NSStringFromClass(HomeMediaCollectionViewCell.class);
    UINib *mediaCellNib = [UINib nibWithNibName:mediaCellIdentifier bundle:nil];
    [self.collectionView registerNib:mediaCellNib forCellWithReuseIdentifier:mediaCellIdentifier];
      
    NSString *headerViewIdentifier = NSStringFromClass(HomeMediaCollectionHeaderView.class);
    UINib *headerNib = [UINib nibWithNibName:headerViewIdentifier bundle:nil];
    [self.collectionView registerNib:headerNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerViewIdentifier];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark Getters and setters

- (void)setHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo featured:(BOOL)featured
{
    [super setHomeSectionInfo:homeSectionInfo featured:featured];
    
    UIColor *backgroundColor = UIColor.play_blackColor;
    if (homeSectionInfo.module && ! ApplicationConfiguration.sharedApplicationConfiguration.moduleColorsDisabled) {
        backgroundColor = homeSectionInfo.module.backgroundColor;
    }
    self.backgroundColor = backgroundColor;
    
    [self.collectionView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (homeSectionInfo) {
            // Restore position in rows when scrolling vertically and returning to a previously scrolled row
            CGPoint maxContentOffset = self.collectionView.play_maximumContentOffset;
            CGPoint contentOffset = CGPointMake(fmaxf(fminf(homeSectionInfo.contentOffset.x, maxContentOffset.x), 0.f),
                                                homeSectionInfo.contentOffset.y);
            [self.collectionView setContentOffset:contentOffset animated:NO];
        }
        self.collectionView.scrollEnabled = (homeSectionInfo.items.count != 0);
    });
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return ! [self isEmpty] ? self.homeSectionInfo.items.count : 10 /* Display 10 placeholders */;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(HomeMediaCollectionViewCell.class) forIndexPath:indexPath];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSAssert([kind isEqualToString:UICollectionElementKindSectionHeader], @"Only section headers are currently used");
    
    HomeMediaCollectionHeaderView *homeMediaCollectionHeaderView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                      withReuseIdentifier:NSStringFromClass(HomeMediaCollectionHeaderView.class)
                                                                                                             forIndexPath:indexPath];
    homeMediaCollectionHeaderView.leftEdgeInset = HomeStandardMargin;
    return homeMediaCollectionHeaderView;
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(HomeMediaCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGMedia *media = ! [self isEmpty] ? self.homeSectionInfo.items[indexPath.row] : nil;
    [cell setMedia:media module:self.homeSectionInfo.module featured:self.featured];
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
        [self.nearestViewController play_presentMediaPlayerWithMedia:media position:nil airPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // For compact layouts, display a single item with the full available collection width (up to a small margin)
    if (self.featured
            && [self collectionView:collectionView numberOfItemsInSection:indexPath.section] == 1
            && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        return CGSizeMake(CGRectGetWidth(collectionView.frame) - 2 * HomeStandardMargin, CGRectGetHeight(collectionView.frame));
    }
    else {
        return [HomeMediaListTableViewCell itemSizeForHomeSectionInfo:self.homeSectionInfo bounds:collectionView.bounds featured:self.featured];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (self.homeSectionInfo.module || self.homeSectionInfo.topic.imageURL) {
        CGSize size = [self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        size.width += HomeStandardMargin;
        return size;
    }
    else {
        return CGSizeZero;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    // If a single item has been displayed, center it
    if (self.featured && [self collectionView:collectionView numberOfItemsInSection:section] == 1) {
        CGSize cellSize = [self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathWithIndex:section]];
        CGFloat margin = (CGRectGetWidth(collectionView.frame) - cellSize.width) / 2.f;
        return UIEdgeInsetsMake(0.f, margin, 0.f, margin);
    }
    else if (self.homeSectionInfo.module) {
        return UIEdgeInsetsMake(0.f, collectionViewLayout.minimumInteritemSpacing, 0.f, HomeStandardMargin);
    }
    else {
        return UIEdgeInsetsMake(0.f, HomeStandardMargin, 0.f, HomeStandardMargin);
    }
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Delay content offset recording so that we don't record a content offset before restoring a content offset
    // (which also is made with a slight delay)
    dispatch_async(dispatch_get_main_queue(), ^{
        self.homeSectionInfo.contentOffset = scrollView.contentOffset;
    });
}

@end
