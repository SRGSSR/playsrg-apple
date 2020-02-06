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
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_accessibilityLabels;
    dispatch_once(&s_onceToken, ^{
        s_accessibilityLabels = @{ @(GCKUIButtonStatePause) : PlaySRGAccessibilityLocalizedString(@"Play", @"Play button label"),
                                   @(GCKUIButtonStatePlay) : PlaySRGAccessibilityLocalizedString(@"Pause", @"Play button label"),
                                   @(GCKUIButtonStatePlayLive) : PlaySRGAccessibilityLocalizedString(@"Stop", @"Play button label") };
    });
    
    return s_accessibilityLabels[@(self.buttonState)];
}

@end
