//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"
#import "TableRequestViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface SongsViewController : TableRequestViewController <ContentInsets>

- (instancetype)initWithChannel:(SRGChannel *)channel letterboxController:(SRGLetterboxController *)letterboxController;

@property (nonatomic, readonly) SRGChannel *channel;
@property (nonatomic, nullable) NSDateInterval *dateInterval;

- (void)scrollToSongAtDate:(nullable NSDate *)date animated:(BOOL)animated;

- (void)updateSelectionForSongAtDate:(nullable NSDate *)date;
- (void)updateSelectionForCurrentSong;

- (void)updateProgressForDateInterval:(nullable NSDateInterval *)dateInterval;

@end

NS_ASSUME_NONNULL_END
