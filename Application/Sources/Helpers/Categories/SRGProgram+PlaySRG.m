//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGProgram+PlaySRG.h"

@implementation SRGProgram (PlaySRG)

- (BOOL)play_containsDate:(NSDate *)date
{
    NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:self.startDate endDate:self.endDate];
    return [dateInterval containsDate:date];
}

@end
