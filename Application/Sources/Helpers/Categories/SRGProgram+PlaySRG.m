//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGProgram+PlaySRG.h"

#import "NSBundle+PlaySRG.h"
#import "PlayAccessibilityFormatter.h"

@implementation SRGProgram (PlaySRG)

- (BOOL)play_containsDate:(NSDate *)date
{
    // Avoid potential crashes if data is incorrect
    NSDate *startDate = [self.startDate earlierDate:self.endDate];
    NSDate *endDate = [self.endDate laterDate:self.startDate];
    
    NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:startDate endDate:endDate];
    return [dateInterval containsDate:date];
}

- (NSString *)play_accessibilityLabelWithChannel:(SRGChannel *)channel
{
    NSString *label = [NSString stringWithFormat:PlaySRGAccessibilityLocalizedString(@"From %1$@ to %2$@", @"Text providing program time information. First placeholder is the start time, second is the end time."), PlayAccessibilityTimeFromDate(self.startDate), PlayAccessibilityTimeFromDate(self.endDate)];
    if (channel) {
        label = [label stringByAppendingString:@" "];
        label = [label stringByAppendingFormat:PlaySRGAccessibilityLocalizedString(@"on %@", @"Text providing a channel information. Placeholder is the channel on which it's broadcasted."), channel.title];
    }
    return [label stringByAppendingFormat:@", %@", self.title];
}

@end
