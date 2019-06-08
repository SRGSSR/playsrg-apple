//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSettings.h"

#import "MediaPlayerViewController.h"
#import "PlayApplication.h"
#import "UIWindow+PlaySRG.h"

#import <FXReachability/FXReachability.h>
#import <InAppSettingsKit/IASKSettingsReader.h>
#import <InAppSettingsKit/IASKSpecifier.h>
#import <libextobjc/libextobjc.h>
#import <SRGLetterbox/SRGLetterbox.h>

NSString * const PlaySRGSettingAlternateRadioHomepageDesignEnabled = @"PlaySRGSettingAlternateRadioHomepageDesignEnabled";
NSString * const PlaySRGSettingHDOverCellularEnabled = @"PlaySRGSettingHDOverCellularEnabled";
NSString * const PlaySRGSettingOriginalImagesOnlyEnabled = @"PlaySRGSettingOriginalImagesOnlyEnabled";
NSString * const PlaySRGSettingPresenterModeEnabled = @"PlaySRGSettingPresenterModeEnabled";
NSString * const PlaySRGSettingStandaloneEnabled = @"PlaySRGSettingStandaloneEnabled";
NSString * const PlaySRGSettingAutoplayEnabled = @"PlaySRGSettingAutoplayEnabled";

NSString * const PlaySRGSettingLastLoggedInEmailAddress = @"PlaySRGSettingLastLoggedInEmailAddress";
NSString * const PlaySRGSettingLastOpenHomepageUid = @"PlaySRGSettingLastOpenHomepageUid";
NSString * const PlaySRGSettingLastPlayedRadioLiveURN = @"PlaySRGSettingLastPlayedRadioLiveURN";
NSString * const PlaySRGSettingSelectedLiveStreamURNForChannels = @"PlaySRGSettingSelectedLiveStreamURNForChannels";
NSString * const PlaySRGSettingServiceURL = @"PlaySRGSettingServiceURL";
NSString * const PlaySRGSettingUserLocation = @"PlaySRGSettingUserLocation";

NSValueTransformer *SettingUserLocationTransformer(void)
{
    static NSValueTransformer *s_transformer;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{ @"WW" : @(SettingUserLocationOutsideCH),
                                                                                         @"CH" : @(SettingUserLocationIgnored) }
                                                                         defaultValue:@(SettingUserLocationDefault)
                                                                  reverseDefaultValue:nil];
    });
    return s_transformer;
}
__attribute__((constructor)) static void ApplicationSettingsInit(void)
{
    [NSUserDefaults.standardUserDefaults registerDefaults:@{ PlaySRGSettingAlternateRadioHomepageDesignEnabled : @NO,
                                                             PlaySRGSettingHDOverCellularEnabled : @YES,
                                                             PlaySRGSettingOriginalImagesOnlyEnabled : @NO,
                                                             PlaySRGSettingPresenterModeEnabled : @NO,
                                                             PlaySRGSettingStandaloneEnabled : @NO,
                                                             PlaySRGSettingAutoplayEnabled : @YES }];
    [NSUserDefaults.standardUserDefaults synchronize];
}

BOOL ApplicationSettingAlternateRadioHomepageDesignEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingAlternateRadioHomepageDesignEnabled];
}

BOOL ApplicationSettingOriginalImagesOnlyEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingOriginalImagesOnlyEnabled];
}

BOOL ApplicationSettingPresenterModeEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingPresenterModeEnabled];
}

BOOL ApplicationSettingStandaloneEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingStandaloneEnabled];
}

SRGQuality ApplicationSettingPreferredQuality(void)
{
    BOOL HQOverCellularEnabled = [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingHDOverCellularEnabled];
    if ([FXReachability sharedInstance].status == FXReachabilityStatusReachableViaWWAN) {
        return HQOverCellularEnabled ? SRGQualityHD : SRGQualitySD;
    }
    else {
        return SRGQualityHD;
    }
}

SRGLetterboxPlaybackSettings *ApplicationSettingPlaybackSettings(void)
{
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.standalone = ApplicationSettingStandaloneEnabled();
    settings.quality = ApplicationSettingPreferredQuality();
    return settings;
}

NSURL *ApplicationSettingServiceURL(void)
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    // Processes run once in the lifetime of the application
    __block BOOL settingServiceURLReset = YES;
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        settingServiceURLReset = NO;
        completionHandler(YES);
    }, @"SettingServiceURLReset2", nil);
    
    if (! settingServiceURLReset) {
        NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
        [userDefaults removeObjectForKey:PlaySRGSettingServiceURL];
        [userDefaults synchronize];
    }
    
    NSString *URLString = [NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingServiceURL];
    NSURL *URL = URLString ? [NSURL URLWithString:URLString] : nil;
    return URL ?: SRGIntegrationLayerProductionServiceURL();
#else
    return SRGIntegrationLayerProductionServiceURL();
#endif
}

void ApplicationSetSettingServiceURL(NSURL *serviceURL)
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    if (serviceURL) {
        [userDefaults setObject:serviceURL.absoluteString forKey:PlaySRGSettingServiceURL];
    }
    else {
        [userDefaults removeObjectForKey:PlaySRGSettingServiceURL];
    }
    [userDefaults synchronize];
#endif
}

NSDictionary<NSString *, NSString *> *ApplicationSettingGlobalParameters(void)
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_locations;
    dispatch_once(&s_onceToken, ^{
        s_locations = @{ @(SettingUserLocationOutsideCH) : @"WW",
                         @(SettingUserLocationIgnored) : @"CH" };
    });
    
    SettingUserLocation userLocation = [[SettingUserLocationTransformer() transformedValue:[NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingUserLocation]] integerValue];
    NSString *location = s_locations[@(userLocation)];
    return location ? @{ @"forceLocation" : location } : nil;
#else
    return nil;
#endif
}

NSTimeInterval ApplicationSettingContinuousPlaybackTransitionDuration(void)
{
    if ([NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingAutoplayEnabled]) {
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            return ApplicationConfiguration.sharedApplicationConfiguration.continuousPlaybackBackgroundTransitionDuration;
        }
        else {
            UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.play_topViewController;
            if ([topViewController isKindOfClass:MediaPlayerViewController.class]) {
                return ApplicationConfiguration.sharedApplicationConfiguration.continuousPlaybackPlayerViewTransitionDuration;
            }
            else {
                return ApplicationConfiguration.sharedApplicationConfiguration.continuousPlaybackForegroundTransitionDuration;
            }
        }
    }
    else {
        return SRGLetterboxContinuousPlaybackDisabled;
    }
}

NSString *ApplicationSettingSelectedLiveStreamURNForChannelUid(NSString *channelUid)
{
    NSDictionary *selectedLiveStreamURNForChannels = [NSUserDefaults.standardUserDefaults dictionaryForKey:PlaySRGSettingSelectedLiveStreamURNForChannels];
    return selectedLiveStreamURNForChannels[channelUid];
}

void ApplicationSettingSetSelectedLiveStreamURNForChannelUid(NSString *channelUid, NSString *mediaURN)
{
    if (channelUid) {
        NSDictionary *selectedLiveStreamURNForChannels = [NSUserDefaults.standardUserDefaults dictionaryForKey:PlaySRGSettingSelectedLiveStreamURNForChannels];
        NSMutableDictionary *mutableSelectedLiveStreamURNForChannels = selectedLiveStreamURNForChannels.mutableCopy ?: NSMutableDictionary.new;
        mutableSelectedLiveStreamURNForChannels[channelUid] = mediaURN;
        
        [NSUserDefaults.standardUserDefaults setObject:mutableSelectedLiveStreamURNForChannels.copy
                                                forKey:PlaySRGSettingSelectedLiveStreamURNForChannels];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

SRGMedia *ApplicationSettingSelectedLivestreamMediaForChannelUid(NSString *channelUid, NSArray<SRGMedia *> *medias)
{
    if (! channelUid) {
        return nil;
    }
    
    NSString *selectedLiveStreamURN = ApplicationSettingSelectedLiveStreamURNForChannelUid(channelUid);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGMedia.new, URN), selectedLiveStreamURN];
    return [medias filteredArrayUsingPredicate:predicate].firstObject;
}

MenuItemInfo *ApplicationSettingLastOpenHomepageMenuItemInfo(void)
{
    NSString *lastOpenHomepageUid = [NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingLastOpenHomepageUid];
    RadioChannel *radioChannel = [ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:lastOpenHomepageUid];
    if (radioChannel) {
        return [MenuItemInfo menuItemInfoWithRadioChannel:radioChannel];
    }
    else {
        return [MenuItemInfo menuItemInfoWithMenuItem:MenuItemTVOverview];
    }
}

void ApplicationSettingSetLastOpenHomepageMenuItemInfo(MenuItemInfo *menuItemInfo)
{
    // Save only radio home page or set to nil if it's the TV home page
    if (menuItemInfo.radioChannel || menuItemInfo.menuItem == MenuItemTVOverview
            || menuItemInfo.menuItem == MenuItemTVByDate || menuItemInfo.menuItem == MenuItemTVShowAZ) {
        [NSUserDefaults.standardUserDefaults setObject:menuItemInfo.radioChannel.uid
                                                forKey:PlaySRGSettingLastOpenHomepageUid];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

NSURL * ApplicationSettingServiceURLForTitle(NSString *title)
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    IASKSettingsReader *settingsReader = [[IASKSettingsReader alloc] initWithFile:@"Root.inApp.server"];
    IASKSpecifier *specifier = [settingsReader specifierForKey:PlaySRGSettingServiceURL];
    NSInteger index = [[specifier multipleTitles] indexOfObjectPassingTest:^BOOL(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj caseInsensitiveCompare:title] == NSOrderedSame;
    }];
    if (index != NSNotFound) {
        NSString *URLString = [[specifier multipleValues] objectAtIndex:index];
        return [NSURL URLWithString:URLString];
    }
    else {
        return nil;
    }
#else
    return nil;
#endif
}
