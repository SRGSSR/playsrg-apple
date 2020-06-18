//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProgramTableViewCell : UITableViewCell

- (void)setProgram:(SRGProgram *)program mediaType:(SRGMediaType)mediaType playing:(BOOL)playing;
- (void)updateProgressForMediaURN:(nullable NSString *)mediaURN date:(NSDate *)date dateInterval:(NSDateInterval *)dateInterval;

@end

NS_ASSUME_NONNULL_END
