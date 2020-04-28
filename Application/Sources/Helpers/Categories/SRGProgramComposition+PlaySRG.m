//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGProgramComposition+PlaySRG.h"

#import <libextobjc/libextobjc.h>

@implementation SRGProgramComposition (PlaySRG)

- (NSArray<SRGProgram *> *)play_programsMatchingMediaURNs:(NSArray<NSString *> *)mediaURNs
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", @keypath(SRGProgram.new, mediaURN), mediaURNs];
    return [self.programs filteredArrayUsingPredicate:predicate];
}

- (NSArray<SRGProgram *> *)play_programsMatchingSegments:(NSArray<SRGSegment *> *)segments
{
    NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(SRGSegment.new, URN)];
    NSArray<NSString *> *mediaURNs = [segments valueForKeyPath:keyPath];
    return [self play_programsMatchingMediaURNs:mediaURNs];
}

@end
