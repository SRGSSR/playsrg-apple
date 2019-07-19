//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Service responsible for retrieving the deep link convert file, and convert web urls to scheme urls.
 */
@interface DeepLinkService : NSObject

/**
 *  Service singleton.
 */
@property (class, nonatomic, readonly) DeepLinkService *sharedService;

- (nullable NSURL *)schemeURLFromWebURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
