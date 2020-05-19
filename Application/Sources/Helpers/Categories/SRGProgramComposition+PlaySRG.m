//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGProgramComposition+PlaySRG.h"

@implementation SRGProgramComposition (PlaySRG)

- (NSArray<SRGProgram *> *)play_programsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGProgram * _Nullable program, NSDictionary<NSString *,id> * _Nullable bindings) {
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

@end
