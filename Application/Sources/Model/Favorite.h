//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  The deprecated `Favorite` collects all information associated with a favorite, and provides the interface to manage them
 */
@interface Favorite : NSObject <SRGImageMetadata>

/**
 *  Perform migration.
 */
+ (void)migrate;

@end

NS_ASSUME_NONNULL_END
