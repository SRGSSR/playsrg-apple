//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Channel : NSObject

/**
 *  Create the channel from a dictionary. Return `nil` if the dictionary format is incorrect.
 */
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

/**
 *  The unique identifier of the channel.
 */
@property (nonatomic, readonly, copy) NSString *uid;

/**
 *  Local unique identifier for referencing resources in a common way.
 */
@property (nonatomic, readonly, copy) NSString *resourceUid;

/**
 *  The channel name.
 */
@property (nonatomic, readonly, copy) NSString *name;

/**
 *  The channel primary color.
 */
@property (nonatomic, readonly) UIColor *color;

/**
 *  The channel title color.
 */
@property (nonatomic, readonly) UIColor *titleColor;

/**
 *  The channel start color for a gradient view.
 */
@property (nonatomic, readonly) UIColor *gradientStartColor;

/**
 *  The channel end color for a gradient view.
 */
@property (nonatomic, readonly) UIColor *gradientEndColor;

/**
 *  Return `YES` iff the status bar should be dark for this channel.
 */
@property (nonatomic, readonly, getter=hasDarkStatusBar) BOOL darkStatusBar;

@end

NS_ASSUME_NONNULL_END
