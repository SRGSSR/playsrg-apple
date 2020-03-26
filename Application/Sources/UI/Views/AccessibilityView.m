//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AccessibilityView.h"

@implementation AccessibilityView

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return [self.delegate labelForAccessibilityView:self];
}

- (NSString *)accessibilityHint
{
    return [self.delegate hintForAccessibilityView:self];
}


@end
