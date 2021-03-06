//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface ProgramTableViewCell : UITableViewCell

- (void)setProgram:(nullable SRGProgram *)program mediaType:(SRGMediaType)mediaType playing:(BOOL)playing;
- (void)updateProgressForMediaURN:(nullable NSString *)mediaURN date:(NSDate *)date dateInterval:(nullable NSDateInterval *)dateInterval;

@end

NS_ASSUME_NONNULL_END
