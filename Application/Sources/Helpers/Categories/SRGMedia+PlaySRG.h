//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

// FIXME: Ask IL to get this information in a media
/**
 *  Return `YES` iff the URN is related to a live center event.
 */
OBJC_EXPORT BOOL PlayIsSwissTXTURN(NSString *URN);

@interface SRGMedia (PlaySRG)

@property (nonatomic, readonly, getter=play_isToday) BOOL play_today;

// Return a concatenation of lead and summary, iff summary not contains the lead, to avoid duplicate information. 
@property (nonatomic, readonly, nullable) NSString *play_fullSummary;

@property (nonatomic, readonly, getter=play_isSubtilesAvailable) BOOL play_subtilesAvailable;

@property (nonatomic, readonly, getter=play_isAudioDescriptionAvailable) BOOL play_audioDescriptionAvailable;

@end

NS_ASSUME_NONNULL_END
