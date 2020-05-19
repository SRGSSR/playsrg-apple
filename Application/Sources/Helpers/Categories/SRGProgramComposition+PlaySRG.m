//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGProgramComposition+PlaySRG.h"

#import <libextobjc/libextobjc.h>

@implementation SRGProgramComposition (PlaySRG)

- (NSArray<SRGProgram *> *)play_programsMatchingMediaURNs:(NSArray<NSString *> *)mediaURNs fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGProgram * _Nullable program, NSDictionary<NSString *,id> * _Nullable bindings) {
        if (! [mediaURNs containsObject:program.mediaURN]) {
            return NO;
        }
        
        if (fromDate && [program.startDate compare:fromDate] == NSOrderedAscending) {
            return NO;
        }
        
        if (toDate && [toDate compare:program.startDate] == NSOrderedAscending) {
            return NO;
        }
        
        return YES;
    }];
    
    return [self.programs filteredArrayUsingPredicate:predicate];
}

- (NSArray<SRGProgram *> *)play_programsMatchingSegments:(NSArray<SRGSegment *> *)segments fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(SRGSegment.new, URN)];
    NSArray<NSString *> *mediaURNs = [segments valueForKeyPath:keyPath];
    return [self play_programsMatchingMediaURNs:mediaURNs fromDate:fromDate toDate:toDate];
}

@end
