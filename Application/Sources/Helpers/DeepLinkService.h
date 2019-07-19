//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Service responsible for retrieving the deep link conversion file, and to convert web URLs into scheme URLs.
 */
@interface DeepLinkService : NSObject

/**
 *  Service singleton.
 */
@property (class, nonatomic, readonly) DeepLinkService *sharedService;

/**
 *  Converts a web URL into a scheme URL.
 */
- (nullable NSURL *)schemeURLFromWebURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
