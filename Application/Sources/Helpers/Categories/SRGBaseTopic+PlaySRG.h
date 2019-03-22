//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGBaseTopic (PlaySRG) <SRGImageMetadata>

/**
 *  The image URL.
 */
@property (nonatomic, readonly, copy, nullable) NSURL *imageURL;

@end

NS_ASSUME_NONNULL_END
