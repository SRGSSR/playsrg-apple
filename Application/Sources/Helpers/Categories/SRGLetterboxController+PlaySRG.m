//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLetterboxController+PlaySRG.h"

@implementation SRGLetterboxController (PlaySRG)

- (NSDateInterval *)play_dateInterval
{
    CMTimeRange timeRange = self.timeRange;
    NSDate *startDate = [self streamDateForTime:timeRange.start];
    NSDate *endDate = [self streamDateForTime:CMTimeRangeGetEnd(timeRange)];
    if (startDate && endDate) {
        return [[NSDateInterval alloc] initWithStartDate:startDate endDate:endDate];
    }
    else {
        return nil;
    }
}

- (SRGMedia *)play_mainMedia
{
    if (self.mediaComposition) {
        return [self.mediaComposition mediaForSubdivision:self.mediaComposition.mainChapter];
    }
    else {
        return self.media;
    }
}

@end
