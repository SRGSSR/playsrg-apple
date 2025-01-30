//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayFirebaseConfiguration.h"

#import "PlayLogger.h"
#import "PlaySRG-Swift.h"

@import Firebase;
@import SRGAppearance;
@import UIKit;

static HomeSection HomeSectionWithString(NSString *string)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, NSNumber *> *s_sections;
    dispatch_once(&s_onceToken, ^{
        s_sections = @{ @"tvLive" : @(HomeSectionTVLive),
                        @"tvScheduledLivestreams" : @(HomeSectionTVScheduledLivestreams),
                        @"tvScheduledLivestreamsNews" : @(HomeSectionTVScheduledLivestreamsNews),
                        @"tvScheduledLivestreamsSport" : @(HomeSectionTVScheduledLivestreamsSport),
                        @"tvScheduledLivestreamsSignLanguage" : @(HomeSectionTVScheduledLivestreamsSignLanguage),
                        @"tvLiveCenterScheduledLivestreams" : @(HomeSectionTVLiveCenterScheduledLivestreams),
                        @"tvLiveCenterScheduledLivestreamsAll" : @(HomeSectionTVLiveCenterScheduledLivestreamsAll),
                        @"tvLiveCenterEpisodes" : @(HomeSectionTVLiveCenterEpisodes),
                        @"tvLiveCenterEpisodesAll" : @(HomeSectionTVLiveCenterEpisodesAll),
                        @"radioAllShows" : @(HomeSectionRadioAllShows),
                        @"radioFavoriteShows" : @(HomeSectionRadioFavoriteShows),
                        @"radioLatest" : @(HomeSectionRadioLatest),
                        @"radioLatestEpisodes" : @(HomeSectionRadioLatestEpisodes),
                        @"radioLatestEpisodesFromFavorites" : @(HomeSectionRadioLatestEpisodesFromFavorites),
                        @"radioLatestVideos" : @(HomeSectionRadioLatestVideos),
                        @"radioLive" : @(HomeSectionRadioLive),
                        @"radioLiveSatellite" : @(HomeSectionRadioLiveSatellite),
                        @"radioMostPopular" : @(HomeSectionRadioMostPopular),
                        @"radioResumePlayback" : @(HomeSectionRadioResumePlayback),
                        @"radioShowsAccess" : @(HomeSectionRadioShowsAccess),
                        @"radioWatchLater" : @(HomeSectionRadioWatchLater)
        };
    });
    NSNumber *section = s_sections[string];
    return section ? section.integerValue : HomeSectionUnknown;
}

NSArray<NSNumber *> *FirebaseConfigurationHomeSections(NSString *string)
{
    NSMutableArray<NSNumber *> *homeSections = [NSMutableArray array];
    
    NSArray<NSString *> *homeSectionIdentifiers = [string componentsSeparatedByString:@","];
    for (NSString *identifier in homeSectionIdentifiers) {
        HomeSection homeSection = HomeSectionWithString(identifier);
        if (homeSection != HomeSectionUnknown) {
            [homeSections addObject:@(homeSection)];
        }
        else {
            PlayLogWarning(@"configuration", @"Unknown home section identifier %@. Skipped.", identifier);
        }
    }
    
    return homeSections.copy;
}

static NSNumber * TVGuideBouquetWithString(NSString *string)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, NSNumber *> *s_bouqets;
    dispatch_once(&s_onceToken, ^{
        s_bouqets = @{ @"thirdparty" : @(TVGuideBouquetThirdParty),
                       @"rsi" : @(TVGuideBouquetRSI),
                       @"rts" : @(TVGuideBouquetRTS),
                       @"srf" : @(TVGuideBouquetSRF)
        };
    });
    return s_bouqets[string];
}

static BOOL TVGuideBouquetIsMainBouquet(TVGuideBouquet tvGuideBouquet, SRGVendor vendor)
{
    switch (tvGuideBouquet) {
        case TVGuideBouquetThirdParty:
            return NO;
        case TVGuideBouquetRSI:
            return vendor == SRGVendorRSI;
        case TVGuideBouquetRTS:
            return vendor == SRGVendorRTS;
        case TVGuideBouquetSRF:
            return vendor == SRGVendorSRF;
    }
}

NSArray<NSNumber *> *FirebaseConfigurationTVGuideOtherBouquets(NSString *string, SRGVendor vendor)
{
    NSMutableArray<NSNumber *> *tvGuideBouquets = [NSMutableArray array];
    
    NSArray<NSString *> *tvGuideBouquetIdentifiers = [string componentsSeparatedByString:@","];
    for (NSString *identifier in tvGuideBouquetIdentifiers) {
        NSNumber * tvGuideBouquet = TVGuideBouquetWithString(identifier);
        if (tvGuideBouquet != nil) {
            if (!([tvGuideBouquets containsObject:tvGuideBouquet] || TVGuideBouquetIsMainBouquet(tvGuideBouquet.intValue, vendor))) {
                [tvGuideBouquets addObject:tvGuideBouquet];
            }
            else {
                PlayLogWarning(@"configuration", @"TV guide other bouquet identifier %@ duplicated or main one. Skipped.", identifier);
            }
        }
        else {
            PlayLogWarning(@"configuration", @"Unknown TV guide other bouquet identifier %@. Skipped.", identifier);
        }
    }
    
    return tvGuideBouquets.copy;
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
        if ([FIRApp defaultApp] != nil) {
            self.remoteConfig = [FIRRemoteConfig remoteConfig];
        }
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

- (NSDictionary<NSString *, NSArray<UIColor *> *> *)topicColorsForKey:(NSString *)key
{
    NSMutableDictionary *topicColors = [NSMutableDictionary dictionary];
    
    NSDictionary *topicColorsDictionary = [self JSONDictionaryForKey:key];
    for (NSString *topicUrn in topicColorsDictionary) {
        NSDictionary *colors = topicColorsDictionary[topicUrn];
        if ([colors isKindOfClass:NSDictionary.class]) {
            UIColor *firstColor = [UIColor srg_colorFromHexadecimalString:colors[@"firstColor"]];
            UIColor *secondColor = [UIColor srg_colorFromHexadecimalString:colors[@"secondColor"]];
            BOOL reduceBrightness = [colors[@"reduceBrightness"] boolValue];
            if (firstColor && secondColor) {
                CGFloat alpha = reduceBrightness ? 0.65 : 1.;
                topicColors[topicUrn] = @[[firstColor colorWithAlphaComponent:alpha], [secondColor colorWithAlphaComponent:alpha]];
            }
            else {
                PlayLogWarning(@"configuration", @"Topic colors dictionnary is missing valid colors. The content of %@ is not valid.", topicUrn);
            }
        }
        else {
            PlayLogWarning(@"configuration", @"Topic colors dictionnary is not valid. The content of %@ is not valid.", topicUrn);
        }
    }
    
    return topicColors.copy;
}

- (NSArray<NSNumber *> *)tvGuideOtherBouquetsForKey:(NSString *)key vendor:(SRGVendor)vendor
{
    NSString *tvGuideBouquetsString = [self stringForKey:key];
    return tvGuideBouquetsString ? FirebaseConfigurationTVGuideOtherBouquets(tvGuideBouquetsString, vendor) : @[];
}

- (NSDictionary<NSNumber *, NSURL *> *)playURLsForKey:(NSString *)key
{
    static NSDictionary<NSString *, NSNumber *> *s_vendors;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_vendors = @{ @"rsi" : @(SRGVendorRSI),
                       @"rtr" : @(SRGVendorRTR),
                       @"rts" : @(SRGVendorRTS),
                       @"srf" : @(SRGVendorSRF),
                       @"swi" : @(SRGVendorSWI) };
    });
    
    NSMutableDictionary<NSNumber *, NSURL *> *playURLs = [NSMutableDictionary dictionary];
    
    NSDictionary *playURLsDictionary = [self JSONDictionaryForKey:key];
    for (NSString *key in playURLsDictionary) {
        NSNumber *vendor = s_vendors[key];
        if (vendor) {
            NSURL *URL = [NSURL URLWithString:playURLsDictionary[key]];
            if (URL) {
                playURLs[vendor] = URL;
            }
            else {
                PlayLogWarning(@"configuration", @"Play URL configuration is not valid. The URL of %@ is not valid.", key);
            }
        }
        else {
            PlayLogWarning(@"configuration", @"Play URL configuration business unit identifier is not valid. %@ is not valid.", key);
        }
    }
    
    return playURLs.copy;
}

- (NSDictionary<NSString *, NSURL *> *)serviceURLsForKey:(NSString *)key
{
    NSMutableDictionary<NSNumber *, NSURL *> *serviceURLs = [NSMutableDictionary dictionary];

    NSDictionary *serviceURLsDictionary = [self JSONDictionaryForKey:key];
    for (NSString *key in serviceURLsDictionary) {
        if ([ServiceObjC.ids containsObject:key]) {
            NSURL *URL = [NSURL URLWithString:serviceURLsDictionary[key]];
            if (URL) {
                serviceURLs[key] = URL;
            }
            else {
                PlayLogWarning(@"configuration", @"Service URL configuration is not valid. The URL of %@ is not valid.", key);
            }
        }
        else {
            PlayLogWarning(@"configuration", @"Service URL configuration identifier is not valid. %@ is not valid.", key);
        }
    }

    return serviceURLs.copy;
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
        [self.remoteConfig activateWithCompletion:^(BOOL changed, NSError * _Nullable error) {
            if (changed) {
                self.updateBlock(self);
            }
        }];
    }];
}

#pragma mark Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self update];
}

@end
