//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIView+PlaySRG.h"

#import "UIViewController+PlaySRG_Private.h"

#import <CoconutKit/CoconutKit.h>

@implementation UIView (PlaySRG)

#pragma mark Getters and setters

- (BOOL)play_isActuallyHidden
{
    UIView *view = self;
    while (view) {
        if (view.hidden) {
            return YES;
        }
        view = view.superview;
    }
    return NO;
}

@end
