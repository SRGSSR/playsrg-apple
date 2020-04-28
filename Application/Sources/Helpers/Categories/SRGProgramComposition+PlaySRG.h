//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGProgramComposition (PlaySRG)

/**
 *  Returns only programs matching a list of media URNs or segments. Preserves initial ordering.
 */
- (nullable NSArray<SRGProgram *> *)play_programsMatchingMediaURNs:(NSArray<NSString *> *)mediaURNs;
- (nullable NSArray<SRGProgram *> *)play_programsMatchingSegments:(NSArray<SRGSegment *> *)segments;

@end

NS_ASSUME_NONNULL_END
