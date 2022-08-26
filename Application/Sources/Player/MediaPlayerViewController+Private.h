//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerViewController.h"

@import SRGLetterbox;

NS_ASSUME_NONNULL_BEGIN

@interface MediaPlayerViewController (Private)

@property (nonatomic, readonly, weak) IBOutlet UITableView *programsTableView;
@property (nonatomic, readonly) SRGLetterboxController *letterboxController;

@end

NS_ASSUME_NONNULL_END
