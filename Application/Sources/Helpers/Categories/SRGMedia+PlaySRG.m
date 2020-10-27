//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMedia+PlaySRG.h"

@import libextobjc;

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

- (BOOL)play_areSubtitlesAvailable
{
    return [self subtitleVariantsForSource:self.recommendedSubtitleVariantSource].count != 0;
}

- (BOOL)play_isAudioDescriptionAvailable
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGVariant.new, type), @(SRGVariantTypeAudioDescription)];
    NSArray<SRGVariant *> *audioVariants = [self audioVariantsForSource:self.recommendedAudioVariantSource];
    return [audioVariants filteredArrayUsingPredicate:predicate].count != 0;
}

- (BOOL)play_isMultiAudioAvailable
{
    NSArray<SRGVariant *> *audioVariants = [self audioVariantsForSource:self.recommendedAudioVariantSource];
    NSArray<NSLocale *> *locales = [audioVariants valueForKey:@keypath(SRGVariant.new, locale)];
    return [NSSet setWithArray:locales].count > 1;
}

- (BOOL)play_isWebFirst
{
    NSDate *date = NSDate.date;
    return [self.date compare:date] == NSOrderedDescending && [self timeAvailabilityAtDate:date] == SRGTimeAvailabilityAvailable && self.contentType == SRGContentTypeEpisode;
}

@end

#pragma mark Functions

BOOL PlayIsSwissTXTURN(NSString *mediaURN)
{
    return [mediaURN containsString:@":swisstxt:"];
}
