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

@end
