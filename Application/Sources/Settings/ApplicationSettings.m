//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSettings.h"

#import "ApplicationConfiguration.h"
#import "ApplicationSettingsConstants.h"
#import "MediaPlayerViewController.h"
#import "PlaySRG-Swift.h"
#import "UIWindow+PlaySRG.h"

#import <InAppSettingsKit/IASKSettingsReader.h>
#import <InAppSettingsKit/IASKSpecifier.h>

@import FXReachability;
@import libextobjc;
@import SRGLetterbox;

NSString * const PlaySRGSettingLastOpenedRadioChannelUid = @"PlaySRGSettingLastOpenedRadioChannelUid";
NSString * const PlaySRGSettingLastOpenedTabBarItem = @"PlaySRGSettingLastOpenedTabBarItem";
NSString * const PlaySRGSettingDeviceToken = @"PlaySRGSettingDeviceToken";

NSValueTransformer *TabBarItemIdentifierTransformer(void)
{
    static NSValueTransformer *s_transformer;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{ @"videos" : @(TabBarItemIdentifierVideos),
                                                                                         @"audios" : @(TabBarItemIdentifierAudios),
                                                                                         @"livestreams" : @(TabBarItemIdentifierLivestreams),
                                                                                         @"search" : @(TabBarItemIdentifierSearch),
                                                                                         @"profile" : @(TabBarItemIdentifierProfile) }
                                                                         defaultValue:@(TabBarItemIdentifierNone)
                                                                  reverseDefaultValue:nil];
    });
    return s_transformer;
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

NSTimeInterval ApplicationSettingContinuousPlaybackTransitionDuration(void)
{
    if ([NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingAutoplayEnabled]) {
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            return ApplicationConfiguration.sharedApplicationConfiguration.continuousPlaybackBackgroundTransitionDuration;
        }
        else {
            UIViewController *topViewController = UIApplication.sharedApplication.mainTopViewController;
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

BOOL ApplicationSettingSubtitleAvailabilityDisplayed(void)
{
    if (ApplicationConfiguration.sharedApplicationConfiguration.subtitleAvailabilityHidden) {
        return NO;
    }
    
    return UIAccessibilityIsVoiceOverRunning() || [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingSubtitleAvailabilityDisplayed];
}

BOOL ApplicationSettingAudioDescriptionAvailabilityDisplayed(void)
{
    if (ApplicationConfiguration.sharedApplicationConfiguration.audioDescriptionAvailabilityHidden) {
        return NO;
    }
    
    return UIAccessibilityIsVoiceOverRunning() || [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingAudioDescriptionAvailabilityDisplayed];
}

NSString *ApplicationSettingSelectedLivestreamURNForChannelUid(NSString *channelUid)
{
    NSDictionary *selectedLivestreamURNForChannels = [NSUserDefaults.standardUserDefaults dictionaryForKey:PlaySRGSettingSelectedLivestreamURNForChannels];
    return selectedLivestreamURNForChannels[channelUid];
}

void ApplicationSettingSetSelectedLivestreamURNForChannelUid(NSString *channelUid, NSString *mediaURN)
{
    if (channelUid) {
        NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
        
        NSDictionary *selectedLivestreamURNForChannels = [userDefaults dictionaryForKey:PlaySRGSettingSelectedLivestreamURNForChannels];
        NSMutableDictionary *mutableSelectedLivestreamURNForChannels = selectedLivestreamURNForChannels.mutableCopy ?: NSMutableDictionary.new;
        mutableSelectedLivestreamURNForChannels[channelUid] = mediaURN;
        
        [userDefaults setObject:mutableSelectedLivestreamURNForChannels.copy forKey:PlaySRGSettingSelectedLivestreamURNForChannels];
        [userDefaults synchronize];
    }
}

SRGMedia *ApplicationSettingSelectedLivestreamMediaForChannelUid(NSString *channelUid, NSArray<SRGMedia *> *medias)
{
    if (! channelUid) {
        return nil;
    }
    
    NSString *selectedLivestreamURN = ApplicationSettingSelectedLivestreamURNForChannelUid(channelUid);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGMedia.new, URN), selectedLivestreamURN];
    return [medias filteredArrayUsingPredicate:predicate].firstObject;
}

TabBarItemIdentifier ApplicationSettingLastOpenedTabBarItemIdentifier(void)
{
    return [[TabBarItemIdentifierTransformer() transformedValue:[NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingLastOpenedTabBarItem]] integerValue];
}

void ApplicationSettingSetLastOpenedTabBarItemIdentifier(TabBarItemIdentifier tabBarItemIdentifier)
{
    if (tabBarItemIdentifier == TabBarItemIdentifierVideos || tabBarItemIdentifier == TabBarItemIdentifierAudios || tabBarItemIdentifier == TabBarItemIdentifierLivestreams) {
        NSString *tabBarItemIdentifierString = [TabBarItemIdentifierTransformer() reverseTransformedValue:@(tabBarItemIdentifier)];
        
        NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
        [userDefaults setObject:tabBarItemIdentifierString forKey:PlaySRGSettingLastOpenedTabBarItem];
        [userDefaults synchronize];
    }
}

RadioChannel *ApplicationSettingLastOpenedRadioChannel(void)
{
    NSString *radioChannelUid = [NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingLastOpenedRadioChannelUid];
    return radioChannelUid ? [ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:radioChannelUid] : nil;
}

void ApplicationSettingSetLastOpenedRadioChannel(RadioChannel *radioChannel)
{
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    [userDefaults setObject:radioChannel.uid forKey:PlaySRGSettingLastOpenedRadioChannelUid];
    [userDefaults synchronize];
}

NSURL *ApplicationSettingServiceURLForKey(NSString *key)
{
    IASKSettingsReader *settingsReader = [[IASKSettingsReader alloc] initWithFile:@"Root.inApp.server"];
    IASKSpecifier *specifier = [settingsReader specifierForKey:PlaySRGSettingServiceURL];
    
    NSInteger index = [[specifier multipleTitles] indexOfObjectPassingTest:^BOOL(NSString * _Nonnull string, NSUInteger idx, BOOL * _Nonnull stop) {
        return [string caseInsensitiveCompare:key] == NSOrderedSame;
    }];
    if (index != NSNotFound) {
        NSString *URLString = [[specifier multipleValues] objectAtIndex:index];
        return [NSURL URLWithString:URLString];
    }
    else {
        return nil;
    }
}

NSString *ApplicationSettingServiceNameForKey(NSString *key)
{
    IASKSettingsReader *settingsReader = [[IASKSettingsReader alloc] initWithFile:@"Root.inApp.server"];
    IASKSpecifier *specifier = [settingsReader specifierForKey:PlaySRGSettingServiceURL];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSString * _Nullable string, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [string caseInsensitiveCompare:key] == NSOrderedSame;
    }];
    return [[specifier multipleTitles] filteredArrayUsingPredicate:predicate].firstObject;
}

BOOL ApplicationSettingBackgroundVideoPlaybackEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingBackgroundVideoPlaybackEnabled];
}

NSString *ApplicationSettingDeviceToken()
{
    return [NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingDeviceToken];
}

void ApplicationSettingSetDeviceToken(NSString *deviceToken)
{
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    [userDefaults setObject:deviceToken forKey:PlaySRGSettingDeviceToken];
    [userDefaults synchronize];
}
