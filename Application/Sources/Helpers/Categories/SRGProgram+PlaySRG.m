//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGProgram+PlaySRG.h"

@implementation SRGProgram (PlaySRG)

- (BOOL)play_containsDate:(NSDate *)date
{
    // Avoid potential crashes if data is incorrect
    NSDate *startDate = [self.startDate earlierDate:self.endDate];
    NSDate *endDate = [self.endDate laterDate:self.startDate];
    
    NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:startDate endDate:endDate];
    return [dateInterval containsDate:date];
}

@end
