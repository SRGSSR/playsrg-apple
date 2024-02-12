//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DeepLinkAction.h"

#import "PlaySRG-Swift.h"

#if TARGET_OS_IOS
#import "DeepLinkService.h"
#endif

@import libextobjc;

DeepLinkType const DeepLinkTypeMedia = @"media";
DeepLinkType const DeepLinkTypeShow = @"show";
DeepLinkType const DeepLinkTypeTopic = @"topic";
DeepLinkType const DeepLinkTypePage = @"page";
DeepLinkType const DeepLinkTypeHome = @"home";
DeepLinkType const DeepLinkTypeAZ = @"az";
DeepLinkType const DeepLinkTypeByDate = @"bydate";
DeepLinkType const DeepLinkTypeSection = @"section";
DeepLinkType const DeepLinkTypeLivestreams = @"livestreams";
DeepLinkType const DeepLinkTypeSearch = @"search";
DeepLinkType const DeepLinkTypeLink = @"link";
DeepLinkType const DeepLinkTypeUnsupported = @"unsupported";

@interface DeepLinkAction ()

@property (nonatomic) DeepLinkType type;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) AnalyticsEventObjC *analyticsEvent;
@property (nonatomic) NSArray<NSURLQueryItem *> *queryItems;

@end

@implementation DeepLinkAction

#pragma mark Class methods

+ (instancetype)unsupportedActionWithSource:(AnalyticsOpenUrlSource)source
{
    AnalyticsEventObjC *hiddenEvent = [AnalyticsEventObjC openUrlWithAction:AnalyticsOpenUrlActionOpenPlayApp
                                                                                 source:source
                                                                                    urn:nil];
    
    return [[self alloc] initWithType:DeepLinkTypeUnsupported
                           identifier:@""
                 analyticsEvent:hiddenEvent
                           queryItems:nil];
}

+ (instancetype)actionFromURLContext:(UIOpenURLContext *)URLContext
{
    return [self actionFromURL:URLContext.URL source:AnalyticsOpenUrlSourceCustomURL canConvertURL:YES];
}

+ (instancetype)actionFromUniversalLinkURL:(NSURL *)URL
{
    return [self actionFromURL:URL source:AnalyticsOpenUrlSourceUniversalLink canConvertURL:YES];
}

+ (instancetype)actionFromURL:(NSURL *)URL source:(AnalyticsOpenUrlSource)source canConvertURL:(BOOL)canConvertURL
{
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    NSString *type = URLComponents.host.lowercaseString;
    if ([type isEqualToString:DeepLinkTypeMedia]) {
        NSString *mediaURN = URLComponents.path.lastPathComponent;
        if (! mediaURN) {
            return [self unsupportedActionWithSource:source];
        }
        
        AnalyticsEventObjC *hiddenEvent = [AnalyticsEventObjC openUrlWithAction:AnalyticsOpenUrlActionPlayMedia
                                                                                     source:source
                                                                                        urn:mediaURN];
        
        return [[self alloc] initWithType:type
                               identifier:mediaURN
                     analyticsEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([type isEqualToString:DeepLinkTypeShow]) {
        NSString *showURN = URLComponents.path.lastPathComponent;
        if (! showURN) {
            return [self unsupportedActionWithSource:source];
        }
        
        AnalyticsEventObjC *hiddenEvent = [AnalyticsEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayShow
                                                                                     source:source
                                                                                        urn:showURN];
        
        return [[self alloc] initWithType:type
                               identifier:showURN
                     analyticsEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([type isEqualToString:DeepLinkTypeTopic]) {
        NSString *topicURN = URLComponents.path.lastPathComponent;
        if (! topicURN) {
            return [self unsupportedActionWithSource:source];
        }
        
        AnalyticsEventObjC *hiddenEvent = [AnalyticsEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayPage
                                                                                     source:source
                                                                                        urn:topicURN];
        
        return [[self alloc] initWithType:type
                               identifier:topicURN
                     analyticsEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([type isEqualToString:DeepLinkTypePage]) {
        NSString *pageUid = URLComponents.path.lastPathComponent;
        if (! pageUid) {
            return [self unsupportedActionWithSource:source];
        }
        
        AnalyticsEventObjC *hiddenEvent = [AnalyticsEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayPage
                                                                         source:source
                                                                            urn:pageUid];
        
        return [[self alloc] initWithType:type
                               identifier:pageUid
                           analyticsEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([@[ DeepLinkTypeHome, DeepLinkTypeAZ, DeepLinkTypeByDate, DeepLinkTypeSearch, DeepLinkTypeLivestreams ] containsObject:type]) {
        AnalyticsEventObjC *hiddenEvent = [AnalyticsEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayPage
                                                                                     source:source
                                                                                        urn:type];
        
        return [[self alloc] initWithType:type
                               identifier:type
                     analyticsEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([type isEqualToString:DeepLinkTypeSection]) {
        NSString *sectionUid = URLComponents.path.lastPathComponent;
        if (! sectionUid) {
            return [self unsupportedActionWithSource:source];
        }
        
        AnalyticsEventObjC *hiddenEvent = [AnalyticsEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayPage
                                                                                     source:source
                                                                                        urn:sectionUid];
        
        return [[self alloc] initWithType:type
                               identifier:sectionUid
                     analyticsEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([type isEqualToString:DeepLinkTypeLink]) {
        NSString *URLString = [self valueForParameterWithName:@"url" inQueryItems:URLComponents.queryItems];
        if (! URLString) {
            return [self unsupportedActionWithSource:source];
        }
        
        AnalyticsEventObjC *hiddenEvent = [AnalyticsEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayUrl
                                                                                     source:source
                                                                                        urn:URLString];
        
        return [[self alloc] initWithType:type
                               identifier:URLString
                     analyticsEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
#if TARGET_OS_IOS
    else if (canConvertURL) {
        NSURL *convertedURL = [DeepLinkService.currentService customURLFromWebURL:URL];
        if (convertedURL) {
            return [self actionFromURL:convertedURL source:source canConvertURL:NO];
        }
        else {
            return [self unsupportedActionWithSource:source];
        }
    }
#endif
    else {
        return [self unsupportedActionWithSource:source];
    }
}

+ (NSString *)valueForParameterWithName:(NSString *)name inQueryItems:(NSArray<NSURLQueryItem *> *)queryItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(NSURLQueryItem.new, name), name];
    return [queryItems filteredArrayUsingPredicate:predicate].firstObject.value;
}

#pragma mark Object lifecycle

- (instancetype)initWithType:(DeepLinkType)type
                  identifier:(NSString *)identifier
        analyticsEvent:(AnalyticsEventObjC *)analyticsEvent
                  queryItems:(NSArray<NSURLQueryItem *> *)queryItems

{
    NSParameterAssert(identifier);
    NSParameterAssert(analyticsEvent);
    
    if (self = [super init]) {
        self.type = type;
        self.identifier = identifier;
        self.analyticsEvent = analyticsEvent;
        self.queryItems = queryItems;
    }
    return self;
}

#pragma mark Parameters

- (NSString *)parameterWithName:(NSString *)name
{
    return [DeepLinkAction valueForParameterWithName:name inQueryItems:self.queryItems];
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; type = %@; identifier = %@; parameters: %@>",
            self.class,
            self,
            self.type,
            self.identifier,
            self.queryItems];
}

@end
