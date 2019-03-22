//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIStackView+PlaySRG.h"

@implementation UIStackView (PlaySRG)

- (void)play_setHidden:(BOOL)hidden
{
    [self setHidden:hidden];
    
    for (UIView *subview in self.arrangedSubviews) {
        subview.hidden = hidden;
    }
}

@end
