//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayFirebaseConfiguration.h"

#import "PlayLogger.h"

@import Firebase;
@import UIKit;

static HomeSection HomeSectionWithString(NSString *string)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, NSNumber *> *s_sections;
    dispatch_once(&s_onceToken, ^{
        s_sections = @{ @"tvTrending" : @(HomeSectionTVTrending),
                        @"tvLive" : @(HomeSectionTVLive),
                        @"tvEvents" : @(HomeSectionTVEvents),
                        @"tvTopics" : @(HomeSectionTVTopics),
                        @"tvTopicsAccess" : @(HomeSectionTVTopicsAccess),
                        @"tvLatest" : @(HomeSectionTVLatest),
                        @"tvWebFirst": @(HomeSectionTVWebFirst),
                        @"tvMostPopular" : @(HomeSectionTVMostPopular),
                        @"tvSoonExpiring" : @(HomeSectionTVSoonExpiring),
                        @"tvScheduledLivestreams" : @(HomeSectionTVScheduledLivestreams),
                        @"tvLiveCenter" : @(HomeSectionTVLiveCenter),
                        @"tvShowsAccess" : @(HomeSectionTVShowsAccess),
                        @"tvFavoriteShows" : @(HomeSectionTVFavoriteShows),
#if TARGET_OS_TV
                        @"tvFavoriteLatestEpisodes" : @(HomeSectionTVFavoriteLatestEpisodes),
#endif
                        @"radioLive" : @(HomeSectionRadioLive),
                        @"radioLiveSatellite" : @(HomeSectionRadioLiveSatellite),
                        @"radioLatestEpisodes" : @(HomeSectionRadioLatestEpisodes),
                        @"radioMostPopular" : @(HomeSectionRadioMostPopular),
                        @"radioLatest" : @(HomeSectionRadioLatest),
                        @"radioLatestVideos" : @(HomeSectionRadioLatestVideos),
                        @"radioAllShows" : @(HomeSectionRadioAllShows),
                        @"radioShowsAccess" : @(HomeSectionRadioShowsAccess),
                        @"radioFavoriteShows" : @(HomeSectionRadioFavoriteShows) };
    });
    NSNumber *section = s_sections[string];
    return section ? section.integerValue : HomeSectionUnknown;
}

static TopicSection TopicSectionWithString(NSString *string)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, NSNumber *> *s_sections;
    dispatch_once(&s_onceToken, ^{
        s_sections = @{ @"latest" : @(TopicSectionLatest),
                        @"mostPopular" : @(TopicSectionMostPopular) };
    });
    NSNumber *section = s_sections[string];
    return section ? section.integerValue : TopicSectionUnknown;
}

NSArray<NSNumber *> *FirebaseConfigurationHomeSections(NSString *string)
{
    NSMutableArray<NSNumber *> *homeSections = [NSMutableArray array];
    
    NSArray<NSString *> *homeSectionIdentifiers = [string componentsSeparatedByString:@","];
    for (NSString *identifier in homeSectionIdentifiers) {
        HomeSection homeSection = HomeSectionWithString(identifier);
        if (homeSection != HomeSectionUnknown) {
            // The environment variable SKIP_TV_EVENTS is used to remove events when generating screenshots.
            if (homeSection == HomeSectionTVEvents && [NSProcessInfo.processInfo.arguments containsObject:@"SKIP_TV_EVENTS"]) {
                continue;
            }
            
            [homeSections addObject:@(homeSection)];
        }
        else {
            PlayLogWarning(@"configuration", @"Unknown home section identifier %@. Skipped.", identifier);
        }
    }
    
    return homeSections.copy;
}

NSArray<NSNumber *> *FirebaseConfigurationTopicSections(NSString *string)
{
    NSMutableArray<NSNumber *> *topicSections = [NSMutableArray array];
    
    NSArray<NSString *> *topicSectionIdentifiers = [string componentsSeparatedByString:@","];
    for (NSString *identifier in topicSectionIdentifiers) {
        TopicSection topicSection = TopicSectionWithString(identifier);
        if (topicSection != TopicSectionUnknown) {
            [topicSections addObject:@(topicSection)];
        }
        else {
            PlayLogWarning(@"configuration", @"Unknown topic section with identifier %@. Skipped.", identifier);
        }
    }
    
    return topicSections.copy;
}

@interface PlayFirebaseConfiguration ()

@property (nonatomic) FIRRemoteConfig *remoteConfig;
@property (nonatomic) NSDictionary *dictionary;
@property (nonatomic) void (^updateBlock)(PlayFirebaseConfiguration *);

@end

@implementation PlayFirebaseConfiguration

#pragma mark Class methods

+ (NSDictionary *)dictionaryFromFirebaseConfig:(FIRRemoteConfig *)remoteConfig
{
    NSArray<NSString *> *keys = [remoteConfig allKeysFromSource:FIRRemoteConfigSourceRemote];
    if (keys.count == 0) {
        keys = [remoteConfig allKeysFromSource:FIRRemoteConfigSourceDefault];
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *key in keys) {
        FIRRemoteConfigValue *value = [remoteConfig configValueForKey:key];
        dictionary[key] = value.stringValue ?: value.numberValue;
    }
    
    return dictionary.copy;
}

+ (void)clearFirebaseConfigurationCache
{
#if TARGET_OS_IOS
    NSString *directoryPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
#else
    NSString *directoryPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
#endif
    NSString *remoteConfigurationPathForDatabase = [directoryPath stringByAppendingPathComponent:@"Google/RemoteConfig/RemoteConfig.sqlite3"];
    if ([NSFileManager.defaultManager fileExistsAtPath:remoteConfigurationPathForDatabase]) {
        [NSFileManager.defaultManager removeItemAtPath:remoteConfigurationPathForDatabase error:NULL];
    }
}

#pragma mark Object lifecycle

- (instancetype)initWithDefaultsDictionary:(NSDictionary *)defaultsDictionary updateBlock:(void (^)(PlayFirebaseConfiguration * _Nonnull))updateBlock
{
    if (self = [super init]) {
        self.remoteConfig = [FIRRemoteConfig remoteConfig];
        if (self.remoteConfig) {
#if defined(DEBUG)
            // Make it possible to retrieve the configuration more frequently during development
            // See https://firebase.google.com/support/faq/#remote-config-values
            self.remoteConfig.configSettings = [[FIRRemoteConfigSettings alloc] init];
            self.remoteConfig.configSettings.minimumFetchInterval = 0.;
#endif
            [self.remoteConfig setDefaults:defaultsDictionary];
            
            self.updateBlock = updateBlock;
            
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(applicationDidBecomeActive:)
                                                       name:UIApplicationDidBecomeActiveNotification
                                                     object:nil];
            
            [self update];
        }
        else {
            self.dictionary = defaultsDictionary;
        }
    }
    return self;
}

#pragma mark Value retrieval

- (NSString *)stringForKey:(NSString *)key
{
    if (self.remoteConfig) {
        FIRRemoteConfigValue *value = [self.remoteConfig configValueForKey:key];
        return (value.source != FIRRemoteConfigSourceStatic && value.dataValue.length != 0) ? value.stringValue : nil;
    }
    else {
        id object = self.dictionary[key];
        return [object isKindOfClass:NSString.class] ? object : nil;
    }
}

- (NSNumber *)numberForKey:(NSString *)key
{
    if (self.remoteConfig) {
        FIRRemoteConfigValue *value = [self.remoteConfig configValueForKey:key];
        return (value.source != FIRRemoteConfigSourceStatic && value.dataValue.length != 0) ? value.numberValue : nil;
    }
    else {
        id object = self.dictionary[key];
        return [object isKindOfClass:NSNumber.class] ? object : nil;
    }
}

- (BOOL)boolForKey:(NSString *)key
{
    if (self.remoteConfig) {
        FIRRemoteConfigValue *value = [self.remoteConfig configValueForKey:key];
        return (value.source != FIRRemoteConfigSourceStatic) ? value.boolValue : NO;
    }
    else {
        id object = self.dictionary[key];
        return [object isKindOfClass:NSNumber.class] ? [object boolValue] : NO;
    }
}

- (id)JSONObjectForKey:(NSString *)key
{
    if (self.remoteConfig) {
        FIRRemoteConfigValue *value = [self.remoteConfig configValueForKey:key];
        return (value.source != FIRRemoteConfigSourceStatic && value.dataValue.length != 0) ? value.JSONValue : nil;
    }
    else {
        return self.dictionary[key];
    }
}

- (NSArray *)JSONArrayForKey:(NSString *)key
{
    id JSONObject = [self JSONObjectForKey:key];
    return [JSONObject isKindOfClass:NSArray.class] ? JSONObject : nil;
}

- (NSDictionary *)JSONDictionaryForKey:(NSString *)key
{
    id JSONObject = [self JSONObjectForKey:key];
    return [JSONObject isKindOfClass:NSDictionary.class] ? JSONObject : nil;
}

- (NSArray<NSNumber *> *)homeSectionsForKey:(NSString *)key
{
    NSString *homeSectionsString = [self stringForKey:key];
    return homeSectionsString ? FirebaseConfigurationHomeSections(homeSectionsString) : @[];
}

- (NSArray<NSNumber *> *)topicSectionsForKey:(NSString *)key
{
    NSString *topicSectionsString = [self stringForKey:key];
    return topicSectionsString ? FirebaseConfigurationTopicSections(topicSectionsString) : @[];
}

- (NSArray<RadioChannel *> *)radioChannelsForKey:(NSString *)key defaultHomeSections:(NSArray<NSNumber *> *)defaultHomeSections
{
    NSMutableArray<RadioChannel *> *radioChannels = [NSMutableArray array];
    
    NSArray *radioChannelsJSONArray = [self JSONArrayForKey:key];
    for (id radioChannelDictionary in radioChannelsJSONArray) {
        if ([radioChannelDictionary isKindOfClass:NSDictionary.class]) {
            RadioChannel *radioChannel = [[RadioChannel alloc] initWithDictionary:radioChannelDictionary
                                                              defaultHomeSections:defaultHomeSections];
            if (radioChannel) {
                [radioChannels addObject:radioChannel];
            }
            else {
                PlayLogWarning(@"configuration", @"Radio channel configuration is not valid. The dictionary of %@ is not valid.", radioChannelDictionary[@"uid"]);
            }
        }
        else {
            PlayLogWarning(@"configuration", @"Radio channel configuration is not valid. A dictionary is required.");
        }
    }
    
    return radioChannels.copy;
}

- (NSArray<TVChannel *> *)tvChannelsForKey:(NSString *)key
{
    NSMutableArray<TVChannel *> *tvChannels = [NSMutableArray array];
    
    NSArray *tvChannelsArray = [self JSONArrayForKey:key];
    for (id tvChannelDictionary in tvChannelsArray) {
        if ([tvChannelDictionary isKindOfClass:NSDictionary.class]) {
            TVChannel *tvChannel = [[TVChannel alloc] initWithDictionary:tvChannelDictionary];
            if (tvChannel) {
                [tvChannels addObject:tvChannel];
            }
            else {
                PlayLogWarning(@"configuration", @"TV channel configuration is not valid. The dictionary of %@ is not valid.", tvChannelDictionary[@"uid"]);
            }
        }
        else {
            PlayLogWarning(@"configuration", @"TV channel configuration is not valid. A dictionary is required.");
        }
    }
    return tvChannels.copy;
}

#pragma mark Update

- (void)update
{
    // Cached configuration expiration must be large enough, except in development builds, see
    //   https://firebase.google.com/support/faq/#remote-config-values
#if defined(DEBUG)
    static const NSTimeInterval kExpirationDuration = 30.;
#else
    static const NSTimeInterval kExpirationDuration = 15. * 60.;
#endif
    
    [self.remoteConfig fetchWithExpirationDuration:kExpirationDuration completionHandler:^(FIRRemoteConfigFetchStatus status, NSError * _Nullable error) {
        [self.remoteConfig activateWithCompletion:nil];
        self.updateBlock(self);
    }];
}

#pragma mark Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self update];
}

@end
