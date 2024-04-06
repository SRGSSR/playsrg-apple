//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface SongTableViewCell : UITableViewCell

+ (CGFloat)heightForSong:(nullable SRGSong *)song withCellWidth:(CGFloat)width;

@property (nonatomic, readonly, getter=isPlayable) BOOL playable;

- (void)setSong:(nullable SRGSong *)song playing:(BOOL)playing withCellWidth:(CGFloat)width;
- (void)updateProgressForDateInterval:(nullable NSDateInterval *)dateInterval;

@end

NS_ASSUME_NONNULL_END
