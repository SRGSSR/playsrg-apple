//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGResource (PlaySRG)

@property (nonatomic, readonly, getter=play_areSubtitlesAvailable) BOOL play_subtitlesAvailable;
@property (nonatomic, readonly, getter=play_isAudioDescriptionAvailable) BOOL play_audioDescriptionAvailable;
@property (nonatomic, readonly, getter=play_isMultiAudio) BOOL play_multiAudio;

@end

NS_ASSUME_NONNULL_END
