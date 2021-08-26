//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Service responsible for retrieving the deep link conversion file, and to convert web URLs into custom URLs.
 */
@interface DeepLinkService : NSObject

/**
 *  The service currently set as shared instance, if any.
 */
@property (class, nonatomic, nullable) DeepLinkService *currentService;

/**
 *  Create a new instance update using the service available at the specified URL.
 */
- (instancetype)initWithServiceURL:(NSURL *)serviceURL;

/**
 *  Converts a web URL into a custom URL.
 */
- (nullable NSURL *)customURLFromWebURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
