//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGModule+PlaySRG.h"

#import "UIColor+PlaySRG.h"

@import SRGAppearance;

@implementation SRGModule (PlaySRG)

- (UIColor *)play_backgroundColor
{
    UIColor *backgroundColor = self.backgroundColor;
    
    // TODO: Remove #1A1A1A" test when Play apps and web portal will use the same black background color
    if ([backgroundColor isEqual:[UIColor srg_colorFromHexadecimalString:@"#1A1A1A"]] || [backgroundColor isEqual:UIColor.play_blackColor]) {
        backgroundColor = nil;
    }
    
    return [backgroundColor colorWithAlphaComponent:.3f];
}

@end
