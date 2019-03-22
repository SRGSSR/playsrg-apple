//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <SRGLetterbox/SRGLetterbox.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (PlaySRG)

/**
 *  Return `YES` iff the receiver is actually hidden from view, i.e. is itself hidden or hidden because one of its parents
 *  is.
 */
@property (nonatomic, readonly, getter=play_isActuallyHidden) BOOL play_actuallyHidden;

@end

NS_ASSUME_NONNULL_END
