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

@import FXReachability;
@import libextobjc;
@import SRGLetterbox;

NSString * const PlaySRGSettingLastOpenedRadioChannelUid = @"PlaySRGSettingLastOpenedRadioChannelUid";
NSString * const PlaySRGSettingLastOpenedTabBarItem = @"PlaySRGSettingLastOpenedTabBarItem";

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

BOOL ApplicationSettingBackgroundVideoPlaybackEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingBackgroundVideoPlaybackEnabled];
}

BOOL ApplicationSettingMediaListDividerEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingMediaListDividerEnabled];
}
