//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalytics;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class AnalyticsEventObjC;

typedef NSString * DeepLinkType NS_STRING_ENUM;

/**
 *  Types.
 */
OBJC_EXPORT DeepLinkType const DeepLinkTypeMedia;
OBJC_EXPORT DeepLinkType const DeepLinkTypeShow;
OBJC_EXPORT DeepLinkType const DeepLinkTypeTopic;
OBJC_EXPORT DeepLinkType const DeepLinkTypeMicroPage;
OBJC_EXPORT DeepLinkType const DeepLinkTypePage;
OBJC_EXPORT DeepLinkType const DeepLinkTypeHome;
OBJC_EXPORT DeepLinkType const DeepLinkTypeAZ;
OBJC_EXPORT DeepLinkType const DeepLinkTypeByDate;
OBJC_EXPORT DeepLinkType const DeepLinkTypeSection;
OBJC_EXPORT DeepLinkType const DeepLinkTypeLivestreams;
OBJC_EXPORT DeepLinkType const DeepLinkTypeSearch;
OBJC_EXPORT DeepLinkType const DeepLinkTypeLink;
OBJC_EXPORT DeepLinkType const DeepLinkTypeUnsupported;

/**
 *  Describes a deep link action (also see CUSTOM_URLS_AND_UNIVERSAL_LINKS.md). The list of supported URLs currently includes:
 *
 *    [scheme]://media/[media_urn] (optional query parameters: channel_id=[channel_id], start_time=[start_position_seconds])
 *    [scheme]://show/[show_urn] (optional query parameter: channel_id=[channel_id])
 *    [scheme]://topic/[topic_urn]
 *    [scheme]://page/[page_id]
 *    [scheme]://home (optional query parameters: channel_id=[channel_id])
 *    [scheme]://az (optional query parameters: channel_id=[channel_id], index=[index_letter])
 *    [scheme]://bydate (optional query parameters: channel_id=[channel_id], date=[date] with format yyyy-MM-dd)
 *    [scheme]://section/[section_id]
 *    [scheme]://livestreams
 *    [scheme]://search (optional query parameters: query=[query], media_type=[audio|video])
 *    [scheme]://link?url=[url]
 *    [scheme]://[play_website_url] (use "parsePlayUrl.js" to attempt transforming the URL)
 */
@interface DeepLinkAction : NSObject

/**
 *  Create an action from a URL context. Unsupported URLs are returned as action with the `DeepLinkTypeUnsupported`
 *  type.
 */
+ (instancetype)actionFromURLContext:(UIOpenURLContext *)URLContext;

/**
 *  Create an action from a universal link. Unsupported URLs are returned as action with the `DeepLinkTypeUnsupported`
 *  type.
 */
+ (instancetype)actionFromUniversalLinkURL:(NSURL *)URL;

/**
 *  Action properties.
 */
@property (nonatomic, readonly) DeepLinkType type;
@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly) AnalyticsEventObjC *analyticsEvent;

@property (class, nonatomic, readonly) NSArray<DeepLinkType> *supportedTypes;

/**
 *  Return the parameter matching the specified name, if any.
 */
- (nullable NSString *)parameterWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
