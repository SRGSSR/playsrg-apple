//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationConfiguration.h"

#import "ApplicationSettings.h"
#import "FirebaseConfiguration.h"
#import "PlayLogger.h"
#import "SRGMedia+PlaySRG.h"

@import libextobjc;
@import SRGAppearance;
@import SRGLetterbox;

NSString * const ApplicationConfigurationDidChangeNotification = @"ApplicationConfigurationDidChangeNotification";

static NSString *AnalyticsBusinessUnitIdentifier(NSString *businessUnitIdentifier)
{
    static NSDictionary<NSString *, SRGAnalyticsBusinessUnitIdentifier>  *s_businessUnitIdentifiers;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_businessUnitIdentifiers = @{ @"rsi" : SRGAnalyticsBusinessUnitIdentifierRSI,
                                       @"rtr" : SRGAnalyticsBusinessUnitIdentifierRTR,
                                       @"rts" : SRGAnalyticsBusinessUnitIdentifierRTS,
                                       @"srf" : SRGAnalyticsBusinessUnitIdentifierSRF,
                                       @"swi" : SRGAnalyticsBusinessUnitIdentifierSWI };
    });
    return s_businessUnitIdentifiers[businessUnitIdentifier];
}

static SRGVendor DataProviderVendor(NSString *businessUnitIdentifier)
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
    return s_vendors[businessUnitIdentifier].integerValue;
}

void ApplicationConfigurationApplyControllerSettings(SRGLetterboxController *controller)
{
    controller.serviceURL = SRGDataProvider.currentDataProvider.serviceURL;
    controller.globalParameters = SRGDataProvider.currentDataProvider.globalParameters;
#if TARGET_OS_IOS
    controller.backgroundVideoPlaybackEnabled = ApplicationSettingBackgroundVideoPlaybackEnabled();
#endif
    
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    controller.endTolerance = applicationConfiguration.endTolerance;
    controller.endToleranceRatio = applicationConfiguration.endToleranceRatio;
}

NSTimeInterval ApplicationConfigurationEffectiveEndTolerance(NSTimeInterval duration)
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    CMTime tolerance = SRGMediaPlayerEffectiveEndTolerance(applicationConfiguration.endTolerance, applicationConfiguration.endToleranceRatio, duration);
    return CMTimeGetSeconds(tolerance);
}

@interface ApplicationConfiguration ()

@property (nonatomic) FirebaseConfiguration *firebaseConfiguration;

@property (nonatomic) SRGVendor vendor;

@property (nonatomic, copy) SRGAnalyticsBusinessUnitIdentifier analyticsBusinessUnitIdentifier;
@property (nonatomic) NSInteger analyticsContainer;

@property (nonatomic, copy) NSString *siteName;
@property (nonatomic, copy) NSString *tvSiteName;
@property (nonatomic, copy) NSString *netMetrixIdentifier;

@property (nonatomic, copy) NSString *voiceOverLanguageCode;

#if TARGET_OS_IOS
@property (nonatomic, copy) NSString *googleCastReceiverIdentifier;
#endif
@property (nonatomic, copy) NSNumber *appStoreProductIdentifier;

@property (nonatomic) NSURL *playURL;
@property (nonatomic) NSURL *middlewareURL;
@property (nonatomic) NSURL *identityWebserviceURL;
@property (nonatomic) NSURL *identityWebsiteURL;
@property (nonatomic) NSURL *userDataServiceURL;

@property (nonatomic) NSURL *whatsNewURL;
@property (nonatomic) NSURL *feedbackURL;
@property (nonatomic) NSURL *impressumURL;
@property (nonatomic) NSURL *termsAndConditionsURL;
@property (nonatomic) NSURL *dataProtectionURL;
@property (nonatomic) NSURL *betaTestingURL;
@property (nonatomic) NSURL *tvBetaTestingURL;
@property (nonatomic) NSURL *sourceCodeURL;

@property (nonatomic, getter=areDownloadsHintsHidden) BOOL downloadsHintsHidden;
@property (nonatomic, getter=areMoreEpisodesHidden) BOOL moreEpisodesHidden;

@property (nonatomic, getter=isSubtitleAvailabilityHidden) BOOL subtitleAvailabilityHidden;
@property (nonatomic, getter=isAudioDescriptionAvailabilityHidden) BOOL audioDescriptionAvailabilityHidden;

@property (nonatomic) NSArray<NSNumber *> *videoHomeSections;
@property (nonatomic) NSArray<NSNumber *> *liveHomeSections;

@property (nonatomic) BOOL tvTrendingEpisodesOnly;
@property (nonatomic) NSNumber *tvTrendingEditorialLimit;
@property (nonatomic) BOOL tvTrendingPrefersHeroStage;

@property (nonatomic, getter=isTvFeaturedHomeSectionHeaderHidden) BOOL tvFeaturedHomeSectionHeaderHidden;

@property (nonatomic) NSInteger minimumSocialViewCount;

@property (nonatomic) NSArray<NSNumber *> *topicSections;
@property (nonatomic) NSArray<NSNumber *> *topicSectionsWithSubtopics;

@property (nonatomic, getter=areTopicHomeHeadersHidden) BOOL topicHomeHeadersHidden;

@property (nonatomic) NSArray<RadioChannel *> *radioChannels;
@property (nonatomic) NSArray<NSNumber *> *audioHomeSections;                           // wrap `HomeSection` values

@property (nonatomic) NSArray<TVChannel *> *tvChannels;

@property (nonatomic, getter=isRadioFeaturedHomeSectionHeaderHidden) BOOL radioFeaturedHomeSectionHeaderHidden;

@property (nonatomic) NSUInteger pageSize;

@property (nonatomic) NSTimeInterval continuousPlaybackPlayerViewTransitionDuration;
@property (nonatomic) NSTimeInterval continuousPlaybackForegroundTransitionDuration;
@property (nonatomic) NSTimeInterval continuousPlaybackBackgroundTransitionDuration;

@property (nonatomic) NSTimeInterval endTolerance;
@property (nonatomic) float endToleranceRatio;

@property (nonatomic) NSArray<NSString *> *hiddenOnboardingUids;

@property (nonatomic, getter=isLogoutMenuEnabled) BOOL logoutMenuEnabled;

@property (nonatomic, getter=areSearchSettingsHidden) BOOL searchSettingsHidden;
@property (nonatomic, getter=isSearchSettingSubtitledHidden) BOOL searchSettingSubtitledHidden;
@property (nonatomic, getter=isSearchSortingCriteriumHidden) BOOL searchSortingCriteriumHidden;
@property (nonatomic, getter=isShowsSearchHidden) BOOL showsSearchHidden;

#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
@property (nonatomic) NSURL *overridePlayURL;
#endif

@end

@implementation ApplicationConfiguration

#pragma mark Class methods

+ (ApplicationConfiguration *)sharedApplicationConfiguration
{
    static dispatch_once_t s_onceToken;
    static ApplicationConfiguration *s_applicationConfiguration;
    dispatch_once(&s_onceToken, ^{
        s_applicationConfiguration = [[ApplicationConfiguration alloc] init];
    });
    return s_applicationConfiguration;
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        // Read the embedded configuration JSON
        NSString *configurationFile = [NSBundle.mainBundle pathForResource:@"ApplicationConfiguration" ofType:@"json"];
        NSData *configurationFileData = [NSData dataWithContentsOfFile:configurationFile];
        id defaultsDictionary = [NSJSONSerialization JSONObjectWithData:configurationFileData options:0 error:NULL];
        NSAssert([defaultsDictionary isKindOfClass:NSDictionary.class], @"A valid default configuration dictionary is required");
        
        self.firebaseConfiguration = [[FirebaseConfiguration alloc] initWithDefaultsDictionary:defaultsDictionary updateBlock:^(FirebaseConfiguration * _Nonnull configuration) {
            if (! [self synchronizeWithFirebaseConfiguration:configuration]) {
                PlayLogWarning(@"configuration", @"The newly fetched remote application configuration is invalid and was not applied");
            }
        }];
        
        __unused BOOL isDefaultRemoteConfigValid = [self synchronizeWithFirebaseConfiguration:self.firebaseConfiguration];
        NSAssert(isDefaultRemoteConfigValid, @"The default remote configuration must be valid");
    }
    return self;
}

#pragma mark Getters and setters

- (BOOL)isContinuousPlaybackAvailable
{
    return self.continuousPlaybackBackgroundTransitionDuration != SRGLetterboxContinuousPlaybackDisabled
        || self.continuousPlaybackForegroundTransitionDuration != SRGLetterboxContinuousPlaybackDisabled
        || self.continuousPlaybackPlayerViewTransitionDuration != SRGLetterboxContinuousPlaybackDisabled;
}

#pragma mark Remote configuration

// Return YES iff the activated remote configuration is valid, and stores the corresponding values. If the configuration
// is not valid, the method returns NO and does not synchronize anything (i.e. the values will not be reflected by
// the ApplicationConfiguration instance)
- (BOOL)synchronizeWithFirebaseConfiguration:(FirebaseConfiguration *)firebaseConfiguration
{
    //
    // Mandatory values. Do not update the local configuration if one is missing
    //
    
    NSString *businessUnitIdentifier = [firebaseConfiguration stringForKey:@"businessUnit"];
    SRGVendor vendor = DataProviderVendor(businessUnitIdentifier);
    if (vendor == SRGVendorNone) {
        return NO;
    }
    
    NSString *analyticsBusinessUnitIdentifier = AnalyticsBusinessUnitIdentifier(businessUnitIdentifier);
    if (! analyticsBusinessUnitIdentifier) {
        return NO;
    }
    
    NSNumber *analyticsContainer = [firebaseConfiguration numberForKey:@"container"];
    if (! analyticsContainer) {
        return NO;
    }
    
    NSString *siteName = [firebaseConfiguration stringForKey:@"siteName"];
    if (! siteName) {
        return NO;
    }
    
    NSString *tvSiteName = [firebaseConfiguration stringForKey:@"tvSiteName"];
    if (! tvSiteName) {
        return NO;
    }
    
    NSString *netMetrixIdentifier = [firebaseConfiguration stringForKey:@"netMetrixIdentifier"];
    if (! netMetrixIdentifier) {
        return NO;
    }
    
    NSString *playURLString = [firebaseConfiguration stringForKey:@"playURL"];
    NSURL *playURL = playURLString ? [NSURL URLWithString:playURLString] : nil;
    if (! playURL) {
        return NO;
    }
    
    NSString *middlewareURLString = [firebaseConfiguration stringForKey:@"middlewareURL"];
    NSURL *middlewareURL = middlewareURLString ? [NSURL URLWithString:middlewareURLString] : nil;
    if (! middlewareURL) {
        return NO;
    }
    
    NSString *whatsNewURLString = [firebaseConfiguration stringForKey:@"whatsNewURL"];
    NSURL *whatsNewURL = whatsNewURLString ? [NSURL URLWithString:whatsNewURLString] : nil;
    if (! whatsNewURL) {
        return NO;
    }
    
    NSNumber *appStoreProductIdentifier = [firebaseConfiguration numberForKey:@"appStoreProductIdentifier"];
    if (! appStoreProductIdentifier) {
        return NO;
    }
    
    // Update mandatory values
    self.analyticsBusinessUnitIdentifier = analyticsBusinessUnitIdentifier;
    self.analyticsContainer = analyticsContainer.integerValue;
    self.vendor = vendor;
    self.siteName = siteName;
    self.tvSiteName = tvSiteName;
    self.netMetrixIdentifier = netMetrixIdentifier;
    
    self.playURL = playURL;
    self.middlewareURL = middlewareURL;
    self.whatsNewURL = whatsNewURL;
    
    self.appStoreProductIdentifier = appStoreProductIdentifier;
    
    //
    // Optional values
    //
    
    NSString *voiceOverLanguageCode = [firebaseConfiguration stringForKey:@"voiceOverLanguageCode"];
    self.voiceOverLanguageCode = voiceOverLanguageCode;
    
    NSString *identityWebserviceURLString = [firebaseConfiguration stringForKey:@"identityWebserviceURL"];
    self.identityWebserviceURL = identityWebserviceURLString ? [NSURL URLWithString:identityWebserviceURLString] : nil;
    
    NSString *identityWebsiteURLString = [firebaseConfiguration stringForKey:@"identityWebsiteURL"];
    self.identityWebsiteURL = identityWebsiteURLString ? [NSURL URLWithString:identityWebsiteURLString] : nil;
    
    NSString *userDataServiceURLString = [firebaseConfiguration stringForKey:@"userDataServiceURL"];
    self.userDataServiceURL = userDataServiceURLString ? [NSURL URLWithString:userDataServiceURLString] : nil;
    
    NSString *feedbackURLString = [firebaseConfiguration stringForKey:@"feedbackURL"];
    self.feedbackURL = feedbackURLString ? [NSURL URLWithString:feedbackURLString] : nil;
    
    NSString *impressumURLString = [firebaseConfiguration stringForKey:@"impressumURL"];
    self.impressumURL = impressumURLString ? [NSURL URLWithString:impressumURLString] : nil;
    
    NSString *betaTestingURLString = [firebaseConfiguration stringForKey:@"betaTestingURL"];
    self.betaTestingURL = betaTestingURLString ? [NSURL URLWithString:betaTestingURLString] : nil;
    
    NSString *tvBetaTestingURLString = [firebaseConfiguration stringForKey:@"tvBetaTestingURL"];
    self.tvBetaTestingURL = tvBetaTestingURLString ? [NSURL URLWithString:tvBetaTestingURLString] : nil;

    NSString *sourceCodeURLString = [firebaseConfiguration stringForKey:@"sourceCodeURL"];
    self.sourceCodeURL = sourceCodeURLString ? [NSURL URLWithString:sourceCodeURLString] : nil;
    
    NSString *termsAndConditionsURLString = [firebaseConfiguration stringForKey:@"termsAndConditionsURL"];
    self.termsAndConditionsURL = termsAndConditionsURLString ? [NSURL URLWithString:termsAndConditionsURLString] : nil;
    
    NSString *dataProtectionURLString = [firebaseConfiguration stringForKey:@"dataProtectionURL"];
    self.dataProtectionURL = dataProtectionURLString ? [NSURL URLWithString:dataProtectionURLString] : nil;
    
    NSNumber *minimumSocialViewCount = [firebaseConfiguration numberForKey:@"minimumSocialViewCount"];
    self.minimumSocialViewCount = minimumSocialViewCount ? MAX(minimumSocialViewCount.integerValue, 0) : NSIntegerMax;
    
    self.downloadsHintsHidden = [firebaseConfiguration boolForKey:@"downloadsHintsHidden"];
    self.moreEpisodesHidden = [firebaseConfiguration boolForKey:@"moreEpisodesHidden"];
    
    self.subtitleAvailabilityHidden = [firebaseConfiguration boolForKey:@"subtitleAvailabilityHidden"];
    self.audioDescriptionAvailabilityHidden = [firebaseConfiguration boolForKey:@"audioDescriptionAvailabilityHidden"];
    
    self.videoHomeSections = [firebaseConfiguration homeSectionsForKey:@"videoHomeSections"];
    self.liveHomeSections = [firebaseConfiguration homeSectionsForKey:@"liveHomeSections"];
    
    self.tvTrendingEpisodesOnly = [firebaseConfiguration boolForKey:@"tvTrendingEpisodesOnly"];
    
    NSNumber *tvTrendingEditorialLimit = [firebaseConfiguration numberForKey:@"tvTrendingEditorialLimit"];
    self.tvTrendingEditorialLimit = tvTrendingEditorialLimit ? @(MAX(tvTrendingEditorialLimit.integerValue, 0)) : nil;
    
    self.tvTrendingPrefersHeroStage = [firebaseConfiguration boolForKey:@"tvTrendingPrefersHeroStage"];
    
    self.tvFeaturedHomeSectionHeaderHidden = [firebaseConfiguration boolForKey:@"tvFeaturedHomeSectionHeaderHidden"];
    
    self.topicSections = [firebaseConfiguration topicSectionsForKey:@"topicSections"];
    self.topicSectionsWithSubtopics = [firebaseConfiguration topicSectionsForKey:@"topicSectionsWithSubtopics"];
    
    self.topicHomeHeadersHidden = [firebaseConfiguration boolForKey:@"topicHomeHeadersHidden"];
    
    self.audioHomeSections = [firebaseConfiguration homeSectionsForKey:@"audioHomeSections"];
    
    self.radioFeaturedHomeSectionHeaderHidden = [firebaseConfiguration boolForKey:@"radioFeaturedHomeSectionHeaderHidden"];
    
    self.radioChannels = [firebaseConfiguration radioChannelsForKey:@"radioChannels" defaultHomeSections:self.audioHomeSections];
    self.tvChannels = [firebaseConfiguration tvChannelsForKey:@"tvChannels"];
    
    NSNumber *pageSize = [firebaseConfiguration numberForKey:@"pageSize"];
    self.pageSize = pageSize ? MAX(pageSize.unsignedIntegerValue, 1) : 20;
    
    NSNumber *continuousPlaybackPlayerViewTransitionDuration = [firebaseConfiguration numberForKey:@"continuousPlaybackPlayerViewTransitionDuration"];
    self.continuousPlaybackPlayerViewTransitionDuration = continuousPlaybackPlayerViewTransitionDuration ? fmax(continuousPlaybackPlayerViewTransitionDuration.doubleValue, 0.) : SRGLetterboxContinuousPlaybackDisabled;
    
    NSNumber *continuousPlaybackForegroundTransitionDuration = [firebaseConfiguration numberForKey:@"continuousPlaybackForegroundTransitionDuration"];
    self.continuousPlaybackForegroundTransitionDuration = continuousPlaybackForegroundTransitionDuration ? fmax(continuousPlaybackForegroundTransitionDuration.doubleValue, 0.) : SRGLetterboxContinuousPlaybackDisabled;
    
    NSNumber *continuousPlaybackBackgroundTransitionDuration = [firebaseConfiguration numberForKey:@"continuousPlaybackBackgroundTransitionDuration"];
    self.continuousPlaybackBackgroundTransitionDuration = continuousPlaybackBackgroundTransitionDuration ? fmax(continuousPlaybackBackgroundTransitionDuration.doubleValue, 0.) : SRGLetterboxContinuousPlaybackDisabled;
    
    NSNumber *endTolerance = [firebaseConfiguration numberForKey:@"endTolerance"];
    self.endTolerance = fmax(endTolerance.doubleValue, 0.);
    
    NSNumber *endToleranceRatio = [firebaseConfiguration numberForKey:@"endToleranceRatio"];
    self.endToleranceRatio = fmaxf(endToleranceRatio.floatValue, 0.f);
    
    self.hiddenOnboardingUids = [[firebaseConfiguration stringForKey:@"hiddenOnboardings"] componentsSeparatedByString:@","] ?: @[];
    
    self.searchSettingsHidden = [firebaseConfiguration boolForKey:@"searchSettingsHidden"];
    self.searchSettingSubtitledHidden = [firebaseConfiguration boolForKey:@"searchSettingSubtitledHidden"];
    self.showsSearchHidden = [firebaseConfiguration boolForKey:@"showsSearchHidden"];
    
    self.logoutMenuEnabled = [firebaseConfiguration boolForKey:@"logoutMenuEnabled"];
    
    [NSNotificationCenter.defaultCenter postNotificationName:ApplicationConfigurationDidChangeNotification
                                                      object:self];
    
    return YES;
}

#pragma mark Getters and setters

- (NSURL *)playURL
{
    NSURL *playURL = _playURL;
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    if (self.overridePlayURL) {
        playURL = self.overridePlayURL;
    }
#endif
    return playURL;
}

#pragma mark Helpers

- (RadioChannel *)radioChannelForUid:(NSString *)uid
{
    if (! uid) {
        return nil;
    }
    
    return [self.radioChannels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @keypath(RadioChannel.new, uid), uid]].firstObject;
}

- (TVChannel *)tvChannelForUid:(NSString *)uid
{
    if (! uid) {
        return nil;
    }
    
    return [self.tvChannels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @keypath(TVChannel.new, uid), uid]].firstObject;
}

- (Channel *)channelForUid:(NSString *)uid
{
    return [self radioChannelForUid:uid] ?: [self tvChannelForUid:uid];
}

- (NSURL *)sharingURLForMediaMetadata:(id<SRGMediaMetadata>)mediaMetadata atTime:(CMTime)time;
{
    if (PlayIsSwissTXTURN(mediaMetadata.URN)) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"https://tp.srgssr.ch/p/livecenter?urn=%@", mediaMetadata.URN]];
    }
    else {
        if (! self.playURL) {
            return nil;
        }
        
        static NSDictionary<NSNumber *, NSString *> *s_mediaTypeNames;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_mediaTypeNames = @{ @(SRGMediaTypeVideo) : @"tv",
                                  @(SRGMediaTypeAudio) : @"radio" };
        });
        
        NSString *mediaTypeName = s_mediaTypeNames[@(mediaMetadata.mediaType)];
        if (! mediaTypeName) {
            return nil;
        }
        
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:self.playURL resolvingAgainstBaseURL:NO];
        URLComponents.path = [[[[URLComponents.path stringByAppendingPathComponent:mediaTypeName]
                                stringByAppendingPathComponent:@"redirect"]
                               stringByAppendingPathComponent:@"detail"]
                              stringByAppendingPathComponent:mediaMetadata.uid];
        
        NSInteger position = CMTimeGetSeconds(time);
        if (position > 0) {
            NSArray<NSURLQueryItem *> *queryItems = URLComponents.queryItems ?: @[];
            queryItems = [queryItems arrayByAddingObject:[NSURLQueryItem queryItemWithName:@"startTime" value:@(position).stringValue]];
            URLComponents.queryItems = queryItems;
        }
        
        return URLComponents.URL;
    }
}

- (NSURL *)sharingURLForShow:(SRGShow *)show
{
    if (! self.playURL || ! show) {
        return nil;
    }
    
    static NSDictionary<NSNumber *, NSString *> *s_showTypeNames;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_showTypeNames = @{ @(SRGTransmissionTV) : @"tv",
                             @(SRGTransmissionRadio) : @"radio",
                             @(SRGTransmissionOnline) : @"online" };
    });
    
    NSString *showTypeName = s_showTypeNames[@(show.transmission)];
    if (! showTypeName) {
        return nil;
    }
    
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:self.playURL resolvingAgainstBaseURL:NO];
    URLComponents.path = [[[URLComponents.path stringByAppendingPathComponent:showTypeName]
                           stringByAppendingPathComponent:@"quicklink"]
                          stringByAppendingPathComponent:show.uid];
    return URLComponents.URL;
}

- (NSURL *)sharingURLForModule:(SRGModule *)module
{
    if (! self.playURL || ! module) {
        return nil;
    }
    
    static NSDictionary<NSNumber *, NSString *> *s_moduleTypeNames;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_moduleTypeNames = @{ @(SRGModuleTypeEvent) : @"event" };
    });
    
    NSString *moduleTypeName = s_moduleTypeNames[@(module.moduleType)];
    if (! moduleTypeName) {
        return nil;
    }
    
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:self.playURL resolvingAgainstBaseURL:NO];
    URLComponents.path = [[[URLComponents.path stringByAppendingPathComponent:@"tv"]
                           stringByAppendingPathComponent:moduleTypeName]
                          stringByAppendingPathComponent:module.seoName];
    return URLComponents.URL;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; videoHomeSections = %@; liveHomeSections = %@; radioChannels = %@; audioHomeSections = %@>",
            self.class,
            self,
            self.videoHomeSections,
            self.liveHomeSections,
            self.radioChannels,
            self.audioHomeSections];
}

@end
