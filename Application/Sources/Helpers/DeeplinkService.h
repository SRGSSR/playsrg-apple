//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Service responsible for retrieving the deeplink convert file, and convert web urls to scheme urls.
 */
@interface DeeplinkService : NSObject

/**
 *  Service singleton.
 */
@property (class, nonatomic, readonly) DeeplinkService *sharedService;

- (nullable NSURL *)schemeURLFromWebURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
