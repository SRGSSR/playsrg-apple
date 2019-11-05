//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGResource+PlaySRG.h"

#import <libextobjc/libextobjc.h>

@implementation SRGResource (PlaySRG)

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

- (BOOL)play_isMultiAudio
{
    NSArray<SRGVariant *> *audioVariants = [self audioVariantsForSource:self.recommendedAudioVariantSource];
    NSArray<NSLocale *> *locales = [audioVariants valueForKey:@keypath(SRGVariant.new, locale)];
    return [NSSet setWithArray:locales].count > 1;
}

@end
