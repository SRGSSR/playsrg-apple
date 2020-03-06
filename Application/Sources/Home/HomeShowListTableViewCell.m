//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeShowListTableViewCell.h"

#import "HomeShowCollectionViewCell.h"
#import "Layout.h"
#import "ShowViewController.h"

#import <CoconutKit/CoconutKit.h>
#import <SRGAppearance/SRGAppearance.h>

static const CGFloat HomeStandardMargin = 10.f;

@interface HomeShowListTableViewCell ()

@property (nonatomic, weak) UIView *wrapperView;
@property (nonatomic, weak) UICollectionView *collectionView;

@end

@implementation HomeShowListTableViewCell

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
    return GridLayoutShowStandardItemSize(itemWidth, featured);
}

#pragma mark Object lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = UIColor.clearColor;
        self.selectedBackgroundView.backgroundColor = UIColor.clearColor;
        
        UIView *wrapperView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        wrapperView.backgroundColor = UIColor.clearColor;
        wrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:wrapperView];
        self.wrapperView = wrapperView;
        
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:wrapperView.bounds collectionViewLayout:collectionViewLayout];
        collectionView.backgroundColor = UIColor.clearColor;
        collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        collectionView.alwaysBounceHorizontal = YES;
        collectionView.directionalLockEnabled = YES;
        // Important. If > 1 view on-screen is found on iPhone with this property enabled, none will scroll to top
        collectionView.scrollsToTop = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [wrapperView addSubview:collectionView];
        self.collectionView = collectionView;
        
        // Remark: The collection view is nested in a dummy view to workaround an accessibility bug
        //         See https://stackoverflow.com/a/38798448/760435
        wrapperView.accessibilityElements = @[collectionView];
        
        NSString *showCellIdentifier = NSStringFromClass(HomeShowCollectionViewCell.class);
        UINib *showCellNib = [UINib nibWithNibName:showCellIdentifier bundle:nil];
        [collectionView registerNib:showCellNib forCellWithReuseIdentifier:showCellIdentifier];
    }
    return self;
}

#pragma mark Overrides

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    // Clear the collection
    [self.collectionView reloadData];
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
    
    [self.collectionView reloadData];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return ! [self isEmpty] ? self.homeSectionInfo.items.count : 10 /* Display 10 placeholders */;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(HomeShowCollectionViewCell.class) forIndexPath:indexPath];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(HomeShowCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGShow *show = ! [self isEmpty] ? self.homeSectionInfo.items[indexPath.row] : nil;
    [cell setShow:show featured:self.featured];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (! [self isEmpty]) {
        SRGShow *show = self.homeSectionInfo.items[indexPath.row];
        ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:show fromPushNotification:NO];
        [self.nearestViewController.navigationController pushViewController:showViewController animated:YES];
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
        return [HomeShowListTableViewCell itemSizeForHomeSectionInfo:self.homeSectionInfo bounds:collectionView.bounds featured:self.featured];
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
