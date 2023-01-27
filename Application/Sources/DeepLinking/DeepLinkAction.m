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
@property (nonatomic) AnalyticsHiddenEventObjC *analyticsHiddenEvent;
@property (nonatomic) NSArray<NSURLQueryItem *> *queryItems;

@end

@implementation DeepLinkAction

#pragma mark Class methods

+ (instancetype)unsupportedActionWithOptions:(UISceneOpenURLOptions *)options source:(AnalyticsEventSource)source
{
    AnalyticsHiddenEventObjC *hiddenEvent = [AnalyticsHiddenEventObjC openUrlWithAction:AnalyticsOpenUrlActionOpenPlayApp
                                                                                 source:source
                                                                                    urn:nil
                                                                      sourceApplication:options.sourceApplication];
    
    return [[self alloc] initWithType:DeepLinkTypeUnsupported
                           identifier:@""
                 analyticsHiddenEvent:hiddenEvent
                           queryItems:nil];
}

+ (instancetype)actionFromURLContext:(UIOpenURLContext *)URLContext
{
    return [self actionFromURL:URLContext.URL options:URLContext.options source:AnalyticsEventSourceCustomURL canConvertURL:YES];
}

+ (instancetype)actionFromUniversalLinkURL:(NSURL *)URL
{
    return [self actionFromURL:URL options:nil source:AnalyticsEventSourceUniversalLink canConvertURL:YES];
}

+ (instancetype)actionFromURL:(NSURL *)URL options:(UISceneOpenURLOptions *)options source:(AnalyticsEventSource)source canConvertURL:(BOOL)canConvertURL
{
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    NSString *type = URLComponents.host.lowercaseString;
    if ([type isEqualToString:DeepLinkTypeMedia]) {
        NSString *mediaURN = URLComponents.path.lastPathComponent;
        if (! mediaURN) {
            return [self unsupportedActionWithOptions:options source:source];
        }
        
        AnalyticsHiddenEventObjC *hiddenEvent = [AnalyticsHiddenEventObjC openUrlWithAction:AnalyticsOpenUrlActionPlayMedia
                                                                                     source:source
                                                                                        urn:mediaURN
                                                                          sourceApplication:options.sourceApplication];
        
        return [[self alloc] initWithType:type
                               identifier:mediaURN
                     analyticsHiddenEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([type isEqualToString:DeepLinkTypeShow]) {
        NSString *showURN = URLComponents.path.lastPathComponent;
        if (! showURN) {
            return [self unsupportedActionWithOptions:options source:source];
        }
        
        AnalyticsHiddenEventObjC *hiddenEvent = [AnalyticsHiddenEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayShow
                                                                                     source:source
                                                                                        urn:showURN
                                                                          sourceApplication:options.sourceApplication];
        
        return [[self alloc] initWithType:type
                               identifier:showURN
                     analyticsHiddenEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([type isEqualToString:DeepLinkTypeTopic]) {
        NSString *topicURN = URLComponents.path.lastPathComponent;
        if (! topicURN) {
            return [self unsupportedActionWithOptions:options source:source];
        }
        
        AnalyticsHiddenEventObjC *hiddenEvent = [AnalyticsHiddenEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayPage
                                                                                     source:source
                                                                                        urn:topicURN
                                                                          sourceApplication:options.sourceApplication];
        
        return [[self alloc] initWithType:type
                               identifier:topicURN
                     analyticsHiddenEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([@[ DeepLinkTypeHome, DeepLinkTypeAZ, DeepLinkTypeByDate, DeepLinkTypeSearch, DeepLinkTypeLivestreams ] containsObject:type]) {
        AnalyticsHiddenEventObjC *hiddenEvent = [AnalyticsHiddenEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayPage
                                                                                     source:source
                                                                                        urn:type
                                                                          sourceApplication:options.sourceApplication];
        
        return [[self alloc] initWithType:type
                               identifier:type
                     analyticsHiddenEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([type isEqualToString:DeepLinkTypeSection]) {
        NSString *sectionUid = URLComponents.path.lastPathComponent;
        if (! sectionUid) {
            return [self unsupportedActionWithOptions:options source:source];
        }
        
        AnalyticsHiddenEventObjC *hiddenEvent = [AnalyticsHiddenEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayPage
                                                                                     source:source
                                                                                        urn:sectionUid
                                                                          sourceApplication:options.sourceApplication];
        
        return [[self alloc] initWithType:type
                               identifier:sectionUid
                     analyticsHiddenEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
    else if ([type isEqualToString:DeepLinkTypeLink]) {
        NSString *URLString = [self valueForParameterWithName:@"url" inQueryItems:URLComponents.queryItems];
        if (! URLString) {
            return [self unsupportedActionWithOptions:options source:source];
        }
        
        AnalyticsHiddenEventObjC *hiddenEvent = [AnalyticsHiddenEventObjC openUrlWithAction:AnalyticsOpenUrlActionDisplayUrl
                                                                                     source:source
                                                                                        urn:URLString
                                                                          sourceApplication:options.sourceApplication];
        
        return [[self alloc] initWithType:type
                               identifier:URLString
                     analyticsHiddenEvent:hiddenEvent
                               queryItems:URLComponents.queryItems];
    }
#if TARGET_OS_IOS
    else if (canConvertURL) {
        NSURL *convertedURL = [DeepLinkService.currentService customURLFromWebURL:URL];
        if (convertedURL) {
            return [self actionFromURL:convertedURL options:options source:source canConvertURL:NO];
        }
        else {
            return [self unsupportedActionWithOptions:options source:source];
        }
    }
#endif
    else {
        return [self unsupportedActionWithOptions:options source:source];
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
        analyticsHiddenEvent:(AnalyticsHiddenEventObjC *)analyticsHiddenEvent
                  queryItems:(NSArray<NSURLQueryItem *> *)queryItems

{
    NSParameterAssert(identifier);
    NSParameterAssert(analyticsHiddenEvent);
    
    if (self = [super init]) {
        self.type = type;
        self.identifier = identifier;
        self.analyticsHiddenEvent = analyticsHiddenEvent;
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
