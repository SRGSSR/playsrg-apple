//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchBar.h"

@implementation SearchBar

#pragma mark Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.showsCancelButton = NO;
}

@end
