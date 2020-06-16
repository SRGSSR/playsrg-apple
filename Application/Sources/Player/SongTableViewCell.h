//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SongTableViewCell : UITableViewCell

+ (CGFloat)heightForSong:(nullable SRGSong *)song withCellWidth:(CGFloat)width;

@property (nonatomic, nullable) SRGSong *song;
@property (nonatomic, getter=isEnabled) BOOL enabled;

@property (nonatomic, getter=isPlaying, readonly) BOOL playing;
@property (nonatomic, getter=isLiveOnly, readonly) BOOL liveOnly;
@property (nonatomic, getter=isVideoContent, readonly) BOOL videoContent;

- (void)updatePlayingAnimationStateWithPlaying:(BOOL)playing liveOnly:(BOOL)liveOnly videoContent:(BOOL)videoContent;

@end

NS_ASSUME_NONNULL_END
