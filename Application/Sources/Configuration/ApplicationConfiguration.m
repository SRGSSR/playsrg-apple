//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationConfiguration.h"

#import "ApplicationSettings.h"
#import "ApplicationSettings+Common.h"
#import "PlayFirebaseConfiguration.h"
#import "PlayLogger.h"
#import "PlaySRG-Swift.h"

@import libextobjc;
@import MediaAccessibility;
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
    controller.audioConfigurationBlock = ^AVMediaSelectionOption * _Nonnull(NSArray<AVMediaSelectionOption *> * _Nonnull audioOptions, AVMediaSelectionOption * _Nonnull defaultAudioOption) {
        NSString *lastSelectedLanguageCode = ApplicationSettingLastSelectedAudioLanguageCode();
        if (! lastSelectedLanguageCode) {
            return defaultAudioOption;
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(AVMediaSelectionOption * _Nullable option, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [[option.locale objectForKey:NSLocaleLanguageCode] isEqualToString:lastSelectedLanguageCode];
        }];
        NSArray<AVMediaSelectionOption *> *matchingAudioOptions = [audioOptions filteredArrayUsingPredicate:predicate];
        if (matchingAudioOptions.count == 0) {
            return defaultAudioOption;
        }
        
        NSArray<AVMediaCharacteristic> *characteristics = CFBridgingRelease(MAAudibleMediaCopyPreferredCharacteristics());
        return [AVMediaSelectionGroup mediaSelectionOptionsFromArray:matchingAudioOptions withMediaCharacteristics:characteristics].firstObject ?: matchingAudioOptions.firstObject;
    };
    [controller reloadMediaConfiguration];
    
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

@property (nonatomic) PlayFirebaseConfiguration *firebaseConfiguration;

@property (nonatomic, copy) NSString *businessUnitIdentifier;
@property (nonatomic) SRGVendor vendor;

@property (nonatomic, copy) SRGAnalyticsBusinessUnitIdentifier analyticsBusinessUnitIdentifier;
@property (nonatomic, copy) NSString *analyticsSourceKey;

@property (nonatomic, copy) NSString *siteName;

@property (nonatomic, copy) NSString *voiceOverLanguageCode;

@property (nonatomic, copy) NSNumber *appStoreProductIdentifier;

@property (nonatomic) NSURL *playURL;
@property (nonatomic) NSURL *playServiceURL;
@property (nonatomic) NSURL *middlewareURL;
@property (nonatomic) NSURL *identityWebserviceURL;
@property (nonatomic) NSURL *identityWebsiteURL;
@property (nonatomic) NSURL *userDataServiceURL;

@property (nonatomic) NSURL *whatsNewURL;
@property (nonatomic) NSURL *feedbackURL;
@property (nonatomic) NSURL *faqURL;
@property (nonatomic) NSURL *impressumURL;
@property (nonatomic) NSURL *termsAndConditionsURL;
@property (nonatomic) NSURL *dataProtectionURL;
@property (nonatomic) NSURL *betaTestingURL;
@property (nonatomic) NSURL *sourceCodeURL;

@property (nonatomic, copy) NSString *supportEmailAddress;

@property (nonatomic, getter=areDownloadsHintsHidden) BOOL downloadsHintsHidden;
@property (nonatomic, getter=areShowsUnavailable) BOOL showsUnavailable;
@property (nonatomic, getter=isTvGuideUnavailable) BOOL tvGuideUnavailable;
@property (nonatomic, getter=areTvThirdPartyChannelsAvailable) BOOL tvThirdPartyChannelsAvailable;

@property (nonatomic, getter=isSubtitleAvailabilityHidden) BOOL subtitleAvailabilityHidden;
@property (nonatomic, getter=isAudioDescriptionAvailabilityHidden) BOOL audioDescriptionAvailabilityHidden;
@property (nonatomic, getter=arePosterImagesEnabled) BOOL posterImagesEnabled;

@property (nonatomic) NSArray<NSNumber *> *liveHomeSections;

@property (nonatomic) NSInteger minimumSocialViewCount;

@property (nonatomic) NSArray<RadioChannel *> *radioChannels;
@property (nonatomic) NSArray<NSNumber *> *audioHomeSections;                           // wrap `HomeSection` values

@property (nonatomic) NSArray<TVChannel *> *tvChannels;

@property (nonatomic) NSArray<RadioChannel *> *satelliteRadioChannels;

@property (nonatomic) NSUInteger pageSize;
@property (nonatomic) NSUInteger detailPageSize;

@property (nonatomic) NSTimeInterval continuousPlaybackPlayerViewTransitionDuration;
@property (nonatomic) NSTimeInterval continuousPlaybackForegroundTransitionDuration;
@property (nonatomic) NSTimeInterval continuousPlaybackBackgroundTransitionDuration;

@property (nonatomic) NSTimeInterval endTolerance;
@property (nonatomic) float endToleranceRatio;

@property (nonatomic) NSArray<NSString *> *hiddenOnboardingUids;

@property (nonatomic, getter=areSearchSettingsHidden) BOOL searchSettingsHidden;
@property (nonatomic, getter=isSearchSettingSubtitledHidden) BOOL searchSettingSubtitledHidden;
@property (nonatomic, getter=isShowsSearchHidden) BOOL showsSearchHidden;

@property (nonatomic, getter=isShowLeadPreferred) BOOL showLeadPreferred;

@property (nonatomic, getter=isUserConsentCentralizedRuleSetPreferred) BOOL userConsentCentralizedRuleSetPreferred;
@property (nonatomic, copy) NSString *userConsentDefaultLanguage;

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
        
        self.firebaseConfiguration = [[PlayFirebaseConfiguration alloc] initWithDefaultsDictionary:defaultsDictionary updateBlock:^(PlayFirebaseConfiguration * _Nonnull configuration) {
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
#if TARGET_OS_IOS
    return self.continuousPlaybackBackgroundTransitionDuration != SRGLetterboxContinuousPlaybackDisabled
        || self.continuousPlaybackForegroundTransitionDuration != SRGLetterboxContinuousPlaybackDisabled
        || self.continuousPlaybackPlayerViewTransitionDuration != SRGLetterboxContinuousPlaybackDisabled;
#else
    return self.continuousPlaybackPlayerViewTransitionDuration != SRGLetterboxContinuousPlaybackDisabled;
#endif
}

- (BOOL)arePosterImagesEnabled
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    switch (ApplicationSettingPosterImages()) {
        case SettingPosterImagesForced: {
            return YES;
            break;
        }
        case SettingPosterImagesIgnored: {
            return NO;
            break;
        }
        default: {
            return _posterImagesEnabled;
            break;
        }
    }
#else
    return _posterImagesEnabled;
#endif
}

#pragma mark Remote configuration

// Return YES iff the activated remote configuration is valid, and stores the corresponding values. If the configuration
// is not valid, the method returns NO and does not synchronize anything (i.e. the values will not be reflected by
// the ApplicationConfiguration instance)
- (BOOL)synchronizeWithFirebaseConfiguration:(PlayFirebaseConfiguration *)firebaseConfiguration
{
    //
    // Mandatory values. Do not update the local configuration if one is missing
    //
    
    NSString *businessUnitIdentifier = [firebaseConfiguration stringForKey:@"businessUnit"];
    if (! businessUnitIdentifier) {
        return NO;
    }
    
    SRGVendor vendor = DataProviderVendor(businessUnitIdentifier);
    if (vendor == SRGVendorNone) {
        return NO;
    }
    
    NSString *analyticsBusinessUnitIdentifier = AnalyticsBusinessUnitIdentifier(businessUnitIdentifier);
    if (! analyticsBusinessUnitIdentifier) {
        return NO;
    }

#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSString *analyticsSourceKey = @"39ae8f94-595c-4ca4-81f7-fb7748bd3f04";
#else
    NSString *analyticsSourceKey = [firebaseConfiguration numberForKey:@"sourceKey"];
#endif
    if (! analyticsSourceKey) {
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
    
    NSString *playURLString = [firebaseConfiguration stringForKey:@"playURL"];
    NSURL *playURL = playURLString ? [NSURL URLWithString:playURLString] : nil;
    if (! playURL) {
        return NO;
    }
    
    NSString *playServiceURLString = [firebaseConfiguration stringForKey:@"playServiceURL"];
    NSURL *playServiceURL = playServiceURLString ? [NSURL URLWithString:playServiceURLString] : nil;
    if (! playServiceURL) {
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
    self.businessUnitIdentifier = businessUnitIdentifier;
    self.vendor = vendor;
    self.analyticsBusinessUnitIdentifier = analyticsBusinessUnitIdentifier;
    self.analyticsSourceKey = analyticsSourceKey;
#if TARGET_OS_IOS
    self.siteName = siteName;
#else
    self.siteName = tvSiteName;
#endif
    
    self.playURL = playURL;
    self.playServiceURL = playServiceURL;
    self.middlewareURL = middlewareURL;
    self.whatsNewURL = whatsNewURL;
    
    self.appStoreProductIdentifier = appStoreProductIdentifier;
    
    //
    // Optional values
    //
    
    self.voiceOverLanguageCode = [firebaseConfiguration stringForKey:@"voiceOverLanguageCode"];
    
    NSString *identityWebserviceURLString = [firebaseConfiguration stringForKey:@"identityWebserviceURL"];
    self.identityWebserviceURL = identityWebserviceURLString ? [NSURL URLWithString:identityWebserviceURLString] : nil;
    
    NSString *identityWebsiteURLString = [firebaseConfiguration stringForKey:@"identityWebsiteURL"];
    self.identityWebsiteURL = identityWebsiteURLString ? [NSURL URLWithString:identityWebsiteURLString] : nil;
    
    NSString *userDataServiceURLString = [firebaseConfiguration stringForKey:@"userDataServiceURL"];
    self.userDataServiceURL = userDataServiceURLString ? [NSURL URLWithString:userDataServiceURLString] : nil;
    
    NSString *faqURLString = [firebaseConfiguration stringForKey:@"faqURL"];
    self.faqURL = faqURLString ? [NSURL URLWithString:faqURLString] : nil;
    
    NSString *feedbackURLString = [firebaseConfiguration stringForKey:@"feedbackURL"];
    self.feedbackURL = feedbackURLString ? [NSURL URLWithString:feedbackURLString] : nil;
    
    NSString *impressumURLString = [firebaseConfiguration stringForKey:@"impressumURL"];
    self.impressumURL = impressumURLString ? [NSURL URLWithString:impressumURLString] : nil;
    
    NSString *betaTestingURLString = [firebaseConfiguration stringForKey:@"betaTestingURL"];
    self.betaTestingURL = betaTestingURLString ? [NSURL URLWithString:betaTestingURLString] : nil;

    NSString *sourceCodeURLString = [firebaseConfiguration stringForKey:@"sourceCodeURL"];
    self.sourceCodeURL = sourceCodeURLString ? [NSURL URLWithString:sourceCodeURLString] : nil;
    
    NSString *termsAndConditionsURLString = [firebaseConfiguration stringForKey:@"termsAndConditionsURL"];
    self.termsAndConditionsURL = termsAndConditionsURLString ? [NSURL URLWithString:termsAndConditionsURLString] : nil;
    
    NSString *dataProtectionURLString = [firebaseConfiguration stringForKey:@"dataProtectionURL"];
    self.dataProtectionURL = dataProtectionURLString ? [NSURL URLWithString:dataProtectionURLString] : nil;
    
    self.supportEmailAddress = [firebaseConfiguration stringForKey:@"supportEmailAddress"];
    
    NSNumber *minimumSocialViewCount = [firebaseConfiguration numberForKey:@"minimumSocialViewCount"];
    self.minimumSocialViewCount = minimumSocialViewCount ? MAX(minimumSocialViewCount.integerValue, 0) : NSIntegerMax;
    
    self.downloadsHintsHidden = [firebaseConfiguration boolForKey:@"downloadsHintsHidden"];
    self.showsUnavailable = [firebaseConfiguration boolForKey:@"showsUnavailable"];
    self.tvGuideUnavailable = [firebaseConfiguration boolForKey:@"tvGuideUnavailable"];
    self.tvThirdPartyChannelsAvailable = [firebaseConfiguration boolForKey:@"tvThirdPartyChannelsAvailable"];
    
    self.subtitleAvailabilityHidden = [firebaseConfiguration boolForKey:@"subtitleAvailabilityHidden"];
    self.audioDescriptionAvailabilityHidden = [firebaseConfiguration boolForKey:@"audioDescriptionAvailabilityHidden"];
    self.posterImagesEnabled = [firebaseConfiguration boolForKey:@"posterImagesEnabled"];
    
#if TARGET_OS_IOS
    self.liveHomeSections = [firebaseConfiguration homeSectionsForKey:@"liveHomeSections"];
#else
    self.liveHomeSections = [firebaseConfiguration homeSectionsForKey:@"tvLiveHomeSections"];
#endif
    
    self.audioHomeSections = [firebaseConfiguration homeSectionsForKey:@"audioHomeSections"];
    
    self.radioChannels = [firebaseConfiguration radioChannelsForKey:@"radioChannels" defaultHomeSections:self.audioHomeSections];
    self.tvChannels = [firebaseConfiguration tvChannelsForKey:@"tvChannels"];
    self.satelliteRadioChannels = [firebaseConfiguration radioChannelsForKey:@"satelliteRadioChannels" defaultHomeSections:nil];
    
    NSNumber *pageSize = [firebaseConfiguration numberForKey:@"pageSize"];
    self.pageSize = pageSize ? MAX(pageSize.unsignedIntegerValue, 1) : 20;
    
    NSNumber *detailPageSize = [firebaseConfiguration numberForKey:@"detailPageSize"];
    self.detailPageSize = detailPageSize ? MAX(detailPageSize.unsignedIntegerValue, 1) : 40;
    
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
    
    self.showLeadPreferred = [firebaseConfiguration boolForKey:@"showLeadPreferred"];
    
    self.userConsentCentralizedRuleSetPreferred = [firebaseConfiguration boolForKey:@"userConsentCentralizedRuleSetPreferred"];
    self.userConsentDefaultLanguage = [firebaseConfiguration stringForKey:@"userConsentDefaultLanguage"];
    
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

- (NSArray<RadioChannel *> *)radioHomepageChannels
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == NO", @keypath(RadioChannel.new, homepageHidden)];
    return [self.radioChannels filteredArrayUsingPredicate:predicate];
}

#pragma mark Helpers

- (RadioChannel *)radioChannelForUid:(NSString *)uid
{
    if (! uid) {
        return nil;
    }
    
    NSArray<RadioChannel *> *radioChannels = [self.radioChannels arrayByAddingObjectsFromArray:self.satelliteRadioChannels];
    return [radioChannels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @keypath(RadioChannel.new, uid), uid]].firstObject;
}

- (RadioChannel *)radioHomepageChannelForUid:(NSString *)uid
{
    if (! uid) {
        return nil;
    }
    
    return [self.radioHomepageChannels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @keypath(RadioChannel.new, uid), uid]].firstObject;
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

- (NSURL *)sharingURLForMedia:(SRGMedia *)media atTime:(CMTime)time
{
    if (! self.playURL || ! media) {
        return nil;
    }
    
    if ([SRGMedia PlayIsSwissTXTURN:media.URN]) {
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:self.playURL resolvingAgainstBaseURL:NO];
        URLComponents.path = [[[[URLComponents.path stringByAppendingPathComponent:@"tv"]
                                stringByAppendingPathComponent:@"-"]
                               stringByAppendingPathComponent:@"video"]
                              stringByAppendingPathComponent:@"sport"];
        URLComponents.queryItems = @[ [NSURLQueryItem queryItemWithName:@"urn" value:media.URN] ];
        return URLComponents.URL;
    }
    else if (media.channel.vendor == SRGVendorSSATR) {
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:self.playURL resolvingAgainstBaseURL:NO];
        URLComponents.path = [URLComponents.path stringByAppendingPathComponent:@"embed"];
        URLComponents.queryItems = @[ [NSURLQueryItem queryItemWithName:@"urn" value:media.URN] ];
        return URLComponents.URL;
    }
    else {
        static NSDictionary<NSNumber *, NSString *> *s_mediaTypeNames;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_mediaTypeNames = @{ @(SRGMediaTypeVideo) : @"tv",
                                  @(SRGMediaTypeAudio) : @"radio" };
        });
        
        NSString *mediaTypeName = s_mediaTypeNames[@(media.mediaType)];
        if (! mediaTypeName) {
            return nil;
        }
        
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:self.playURL resolvingAgainstBaseURL:NO];
        URLComponents.path = [[[[URLComponents.path stringByAppendingPathComponent:mediaTypeName]
                                stringByAppendingPathComponent:@"redirect"]
                               stringByAppendingPathComponent:@"detail"]
                              stringByAppendingPathComponent:media.uid];
        
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

- (NSURL *)sharingURLForContentSection:(SRGContentSection *)contentSection
{
    if (! self.playURL || ! contentSection) {
        return nil;
    }
    
    if (! contentSection.presentation.hasDetailPage && ! ApplicationSettingSectionWideSupportEnabled()) {
        return nil;
    }
    
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:self.playURL resolvingAgainstBaseURL:NO];
    URLComponents.path = [[[URLComponents.path stringByAppendingPathComponent:@"tv"]
                           stringByAppendingPathComponent:@"detail"]
                          stringByAppendingPathComponent:@"section"];
    URLComponents.queryItems = @[ [NSURLQueryItem queryItemWithName:@"id" value:contentSection.uid] ];
    return URLComponents.URL;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; liveHomeSections = %@; radioChannels = %@; audioHomeSections = %@>",
            self.class,
            self,
            self.liveHomeSections,
            self.radioChannels,
            self.audioHomeSections];
}

@end
