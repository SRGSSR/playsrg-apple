//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface ActivityItemSource : NSObject <UIActivityItemSource>

/**
 *  Create an activity item source for a media.
 */
- (instancetype)initWithMedia:(SRGMedia *)media URL:(NSURL *)URL;

/**
 *  Create an activity item source for a show.
 */
- (instancetype)initWithShow:(SRGShow *)show URL:(NSURL *)URL;

/**
 *  Create an activity item source for a module.
 */
- (instancetype)initWithModule:(SRGModule *)module URL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
