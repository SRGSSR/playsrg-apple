//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CollectionRequestViewController.h"
#import "RadioChannel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShowsViewController : CollectionRequestViewController

/**
 *  Instantiate for shows belonging to the specified radio channel. If no channel is provided, TV shows will be
 *  displayed instead. The alphabetical index is ingored if not in the loaded index list.
 */
- (instancetype)initWithRadioChannel:(nullable RadioChannel *)radioChannel alphabeticalIndex:(nullable NSString *)alphabeticalIndex;

@end

NS_ASSUME_NONNULL_END
