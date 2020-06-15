//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProgramTableViewCell : UITableViewCell

@property (nonatomic, nullable) SRGProgram *program;
@property (nonatomic, nullable) NSNumber *progress;
@property (nonatomic, getter=isPlaying) BOOL playing;
@property (nonatomic, getter=isLiveOnly) BOOL liveOnly;

@end

NS_ASSUME_NONNULL_END
