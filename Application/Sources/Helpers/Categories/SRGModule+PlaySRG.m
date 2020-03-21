//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGModule+PlaySRG.h"

@implementation SRGModule (PlaySRG)

- (UIColor *)play_backgroundColor
{
    return [self.backgroundColor colorWithAlphaComponent:.3f];
}

@end
