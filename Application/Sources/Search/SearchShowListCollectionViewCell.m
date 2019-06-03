//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchShowListCollectionViewCell.h"

#import "ShowCollectionViewCell.h"
#import "ShowViewController.h"

#import <CoconutKit/CoconutKit.h>

@interface SearchShowListCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

@implementation SearchShowListCollectionViewCell

#pragma mark Getters and setters

- (void)setShows:(NSArray *)shows
{
    _shows = shows;
    [self.collectionView reloadData];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.collectionView.alwaysBounceHorizontal = YES;
    self.collectionView.directionalLockEnabled = YES;
    // Important. If > 1 view on-screen is found on iPhone with this property enabled, none will scroll to top
    self.collectionView.scrollsToTop = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    NSString *showCellIdentifier = NSStringFromClass(ShowCollectionViewCell.class);
    UINib *showCellNib = [UINib nibWithNibName:showCellIdentifier bundle:nil];
    [self.collectionView registerNib:showCellNib forCellWithReuseIdentifier:showCellIdentifier];
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
    cell.show = self.shows[indexPath.row];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGShow *show = self.shows[indexPath.row];
    ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:show fromPushNotification:NO];
    [self.nearestViewController.navigationController pushViewController:showViewController animated:YES];
}

@end
