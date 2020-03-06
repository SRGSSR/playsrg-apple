//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Layout.h"

CGFloat GridLayoutItemWidth(CGFloat itemApproximateWidth, CGFloat layoutWidth, CGFloat leadingInset, CGFloat trailingInset, CGFloat spacing)
{
    CGFloat availableWidth = layoutWidth - leadingInset - trailingInset;
    if (availableWidth <= 0.f) {
        return 0.f;
    }
    
    // For a grid, two items are required at least
    NSInteger numberOfItemsPerRow = MAX((availableWidth + spacing) / (itemApproximateWidth + spacing), 2);
    return (availableWidth - (numberOfItemsPerRow - 1) * spacing) / numberOfItemsPerRow;
}
