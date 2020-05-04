//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class TVChannel;

/**
 *  Images associated with the TV channel.
 */
OBJC_EXPORT UIImage *TVChannelBanner22Image(TVChannel * _Nullable tvChannel);

/**
 *  Image overrides.
 */
OBJC_EXPORT NSString * _Nullable TVChannelImageOverridePath(TVChannel * _Nullable tvChannel, NSString *type);

/**
 *  Represent a TV channel in the application configuration.
 */
@interface TVChannel : NSObject

/**
 *  Create the TV channel from a dictionary. Return `nil` if the dictionary format is incorrect.
 */
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

/**
 *  The unique identifier of the TV channel (`SRGChannel` uid).
 */
@property (nonatomic, readonly, copy) NSString *uid;

/**
 *  The channel name.
 */
@property (nonatomic, readonly, copy) NSString *name;

/**
 *  The channel primary color.
 */
@property (nonatomic, readonly) UIColor *color;

/**
 *  The channel secondary color.
 */
@property (nonatomic, readonly) UIColor *color2;

/**
 *  The channel title color (white by default).
 */
@property (nonatomic, readonly) UIColor *titleColor;

@end

NS_ASSUME_NONNULL_END
