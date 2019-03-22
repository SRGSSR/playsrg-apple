//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Calendar.h"

@interface FSCalendar (PlayPrivateMethods)

@property (nonatomic, readonly) UICollectionView *collectionView;

@end

@implementation Calendar

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSArray *)accessibilityElements
{
    return @[self.collectionView];
}

@end
