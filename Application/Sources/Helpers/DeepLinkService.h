//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NSString * DeeplinkAction NS_STRING_ENUM;

/**
 *  Actions
 */
OBJC_EXPORT DeeplinkAction const DeeplinkActionMedia;
OBJC_EXPORT DeeplinkAction const DeeplinkActionShow;
OBJC_EXPORT DeeplinkAction const DeeplinkActionTopic;
OBJC_EXPORT DeeplinkAction const DeeplinkActionHome;
OBJC_EXPORT DeeplinkAction const DeeplinkActionAZ;
OBJC_EXPORT DeeplinkAction const DeeplinkActionByDate;
OBJC_EXPORT DeeplinkAction const DeeplinkActionSection;
OBJC_EXPORT DeeplinkAction const DeeplinkActionSearch;
OBJC_EXPORT DeeplinkAction const DeeplinkActionLink;

/**
 *  Service responsible for retrieving the deep link conversion file, and to convert web URLs into scheme URLs.
 */
@interface DeepLinkService : NSObject

/**
 *  Create a new instance update using the service available at the specified URL.
 */
- (instancetype)initWithServiceURL:(NSURL *)serviceURL;

/**
 *  Converts a web URL into a scheme URL.
 */
- (nullable NSURL *)schemeURLFromWebURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
