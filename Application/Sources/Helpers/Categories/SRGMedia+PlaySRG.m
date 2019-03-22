//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMedia+PlaySRG.h"

@implementation SRGMedia (PlaySRG)

- (BOOL)play_isToday
{
    return [NSCalendar.currentCalendar isDateInToday:self.date];
}

- (NSString *)play_fullSummary
{
    if (self.lead.length && self.summary.length && ![self.summary containsString:self.lead]) {
        return [NSString stringWithFormat:@"%@\n\n%@", self.lead, self.summary];
    }
    else if (self.summary.length) {
        return self.summary;
    }
    else if (self.lead.length) {
        return self.lead;
    }
    else {
        return nil;
    }
}

@end

#pragma mark Functions

BOOL PlayIsSwissTXTURN(NSString *mediaURN)
{
    return [mediaURN containsString:@":swisstxt:"];
}
