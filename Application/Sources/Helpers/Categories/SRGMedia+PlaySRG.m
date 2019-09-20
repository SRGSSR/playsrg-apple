//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMedia+PlaySRG.h"

#import <libextobjc/libextobjc.h>

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

- (BOOL)play_isSubtilesAvailable
{
    return [self subtitleInformationsForSource:self.recommendedSubtitleInformationSource].count != 0;
}

- (BOOL)play_isAudioDescriptionAvailable
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGAudioTrack.new, type), @(SRGAudioTrackTypeAudioDescription)];
    NSArray<SRGAudioTrack *> *audioTracks = [self audioTracksForSource:self.recommendedAudioTrackSource];
    return [audioTracks filteredArrayUsingPredicate:predicate].count != 0;
}

@end

#pragma mark Functions

BOOL PlayIsSwissTXTURN(NSString *mediaURN)
{
    return [mediaURN containsString:@":swisstxt:"];
}
