//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGProgramComposition (PlaySRG)

/**
 *  Returns only programs matching a list of media URNs. Preserves initial ordering. Date filtering is optional.
 */
- (nullable NSArray<SRGProgram *> *)play_programsMatchingMediaURNs:(NSArray<NSString *> *)mediaURNs
                                                          fromDate:(nullable NSDate *)fromDate
                                                            toDate:(nullable NSDate *)toDate;

/**
 *  Same as the previous method, but for a list of segments.
 */
- (nullable NSArray<SRGProgram *> *)play_programsMatchingSegments:(NSArray<SRGSegment *> *)segments
                                                         fromDate:(nullable NSDate *)fromDate
                                                           toDate:(nullable NSDate *)toDate;

@end

NS_ASSUME_NONNULL_END
