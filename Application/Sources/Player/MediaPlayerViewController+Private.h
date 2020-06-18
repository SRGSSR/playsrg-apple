//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerViewController.h"

#import <SRGLetterbox/SRGLetterbox.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT NSDateInterval * _Nullable MediaPlayerViewControllerDateInterval(SRGLetterboxController *letterboxController);

@interface MediaPlayerViewController (Private)

@property (nonatomic, readonly, weak) IBOutlet UITableView *programsTableView;
@property (nonatomic, readonly) IBOutlet SRGLetterboxController *letterboxController;

@end

NS_ASSUME_NONNULL_END
