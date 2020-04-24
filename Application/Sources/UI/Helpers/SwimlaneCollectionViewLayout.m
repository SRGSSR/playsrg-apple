//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SwimlaneCollectionViewLayout.h"

@implementation SwimlaneCollectionViewLayout

#pragma mark Overrides

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    NSAssert(self.scrollDirection == UICollectionViewScrollDirectionHorizontal, @"Swimlanes must be a horizontal layout");
    
    // Do not snap at the end
    CGFloat maxX = fmaxf(self.collectionViewContentSize.width - CGRectGetWidth(self.collectionView.frame), 0.f);
    if (proposedContentOffset.x >= maxX) {
        return CGPointMake(maxX, proposedContentOffset.y);
    }
    
    // Extract attributes for all items which would be displayed at the proposed offset (sort them to have cells
    // and supplementary views correctly ordered altogether)
    CGRect proposedRect = CGRectMake(proposedContentOffset.x,
                                     proposedContentOffset.y,
                                     CGRectGetWidth(self.collectionView.bounds),
                                     CGRectGetHeight(self.collectionView.bounds));
    NSArray<UICollectionViewLayoutAttributes *> *layoutAttributesInProposedRect = [[self layoutAttributesForElementsInRect:proposedRect] sortedArrayUsingComparator:^NSComparisonResult(UICollectionViewLayoutAttributes * _Nonnull layoutAttributes1, UICollectionViewLayoutAttributes * _Nonnull layoutAttributes2) {
        CGFloat x1 = CGRectGetMinX(layoutAttributes1.frame);
        CGFloat x2 = CGRectGetMinX(layoutAttributes2.frame);
        
        if (x1 == x2) {
            return NSOrderedSame;
        }
        else if (x1 < x2) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedDescending;
        }
    }];
    
    // No item displayed in the rect
    if (layoutAttributesInProposedRect.count == 0) {
        return CGPointMake(fminf(fmaxf(proposedContentOffset.x, 0.f), maxX), proposedContentOffset.y);
    }
    
    UICollectionViewLayoutAttributes *proposedLayoutAttributes = nil;
    
    // Decide on which one of the first two items we should snap (if more than two items)
    UICollectionViewLayoutAttributes *layoutAttributes0 = layoutAttributesInProposedRect.firstObject;
    if (layoutAttributesInProposedRect.count > 1) {
        UICollectionViewLayoutAttributes *layoutAttributes1 = layoutAttributesInProposedRect[1];
        
        // Moving to the right. Snap on the second item
        if (velocity.x > 0.f) {
            proposedLayoutAttributes = layoutAttributes1;
        }
        // Moving to the left. Snap on the first item
        else if (velocity.x < 0.f) {
            proposedLayoutAttributes = layoutAttributes0;
        }
        // Still. Snap on the first item is at least half of it is visible
        else {
            CGRect visibleRect0 = CGRectIntersection(layoutAttributes0.frame, proposedRect);
            
            if (CGRectGetWidth(visibleRect0) < 0.5f * CGRectGetWidth(layoutAttributes0.frame)) {
                proposedLayoutAttributes = layoutAttributes1;
            }
            else {
                proposedLayoutAttributes = layoutAttributes0;
            }
        }
    }
    // Snap on the only available item
    else {
        proposedLayoutAttributes = layoutAttributes0;
    }
    
    // Use twice the margin to snap not at item boundaries but a little before, so that previous items are slightly visible
    CGFloat snapXOffset = fmaxf(CGRectGetMinX(proposedLayoutAttributes.frame) - 2 * self.minimumInteritemSpacing, 0.f);
    return CGPointMake(snapXOffset, proposedContentOffset.y);
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    return [self targetContentOffsetForProposedContentOffset:proposedContentOffset withScrollingVelocity:CGPointZero];
}

@end
