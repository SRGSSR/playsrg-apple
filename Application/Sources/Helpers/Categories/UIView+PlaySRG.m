//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIView+PlaySRG.h"

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

- (UIViewController *)play_nearestViewController
{
    UIResponder *responder = self.nextResponder;
    while (responder) {
        if ([responder isKindOfClass:UIViewController.class] &&
            // Ignore SwiftUI hosting view controllers
            [NSStringFromClass(responder.class) rangeOfString:@"SwiftUI"].location == NSNotFound) {
            return (UIViewController *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

@end
