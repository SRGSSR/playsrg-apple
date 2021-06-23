//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediasViewController.h"
#import "RadioChannel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DailyMediasViewController : MediasViewController

/**
 *  Instantiate for medias belonging to the specified radio channel and date. If no channel is provided, TV medias will
 *  be displayed instead. If date is nil, today's medias will be displayed.
 */
- (instancetype)initWithDate:(nullable NSDate *)date radioChannel:(nullable RadioChannel *)radioChannel;

@property (nonatomic, readonly, nullable) NSDate *date;

@end

NS_ASSUME_NONNULL_END
