//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaComposition+PlaySRG.h"

@import libextobjc;

@implementation SRGMediaComposition (PlaySRG)

- (SRGSubdivision *)play_subdivisionWithURN:(NSString *)URN
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGSubdivision.new, URN), URN];
    SRGSubdivision *subdivision = [self.chapters filteredArrayUsingPredicate:predicate].firstObject;
    if (subdivision) {
        return subdivision;
    }
    else {
        for (SRGChapter *chapter in self.chapters) {
            subdivision = [chapter.segments filteredArrayUsingPredicate:predicate].firstObject;
            if (subdivision) {
                return subdivision;
            }
        }
    }
    return nil;
}

- (BOOL)play_playbackContextWithPreferredSettings:(nullable SRGLetterboxPlaybackSettings *)preferredSettings
                                     contextBlock:(NS_NOESCAPE PlayPlaybackContextBlock)contextBlock
{
    SRGPlaybackSettings *playbackSettings = [[SRGPlaybackSettings alloc] init];
    playbackSettings.streamType = preferredSettings.streamType;
    playbackSettings.quality = preferredSettings.quality;
    playbackSettings.startBitRate = preferredSettings.startBitRate;
    playbackSettings.sourceUid = preferredSettings.sourceUid;
    
    return [self playbackContextWithPreferredSettings:playbackSettings contextBlock:^(NSURL * _Nonnull streamURL, SRGResource * _Nonnull resource, NSArray<id<SRGSegment>> * _Nullable segments, NSInteger index, SRGAnalyticsStreamLabels * _Nullable analyticsLabels) {
        return contextBlock(resource, (NSArray<SRGSegment *> *)segments);
    }];
}

@end
