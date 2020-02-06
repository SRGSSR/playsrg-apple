//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "GoogleCastPlaybackButton.h"

#import "NSBundle+PlaySRG.h"

@implementation GoogleCastPlaybackButton

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    return (self.buttonState == GCKUIButtonStatePause) ? PlaySRGAccessibilityLocalizedString(@"Play", @"Play button label") : PlaySRGAccessibilityLocalizedString(@"Pause", @"Pause button label");
}

@end
