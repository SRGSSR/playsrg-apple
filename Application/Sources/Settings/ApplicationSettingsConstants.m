//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSettingsConstants.h"

NSString * const PlaySRGSettingHDOverCellularEnabled = @"PlaySRGSettingHDOverCellularEnabled";
NSString * const PlaySRGSettingPresenterModeEnabled = @"PlaySRGSettingPresenterModeEnabled";
NSString * const PlaySRGSettingStandaloneEnabled = @"PlaySRGSettingStandaloneEnabled";
NSString * const PlaySRGSettingSectionWideSupportEnabled = @"PlaySRGSettingSectionWideSupportEnabled";
NSString * const PlaySRGSettingPosterImages = @"PlaySRGSettingPosterImages";
NSString * const PlaySRGSettingSquareImages = @"PlaySRGSettingSquareImages";
NSString * const PlaySRGSettingAudioHomepageOption = @"PlaySRGSettingAudioHomepageOption";
NSString * const PlaySRGSettingAutoplayEnabled = @"PlaySRGSettingAutoplayEnabled";
NSString * const PlaySRGSettingBackgroundVideoPlaybackEnabled = @"PlaySRGSettingBackgroundVideoPlaybackEnabled";
NSString * const PlaySRGSettingSubtitleAvailabilityDisplayed = @"PlaySRGSettingSubtitleAvailabilityDisplayed";
NSString * const PlaySRGSettingAudioDescriptionAvailabilityDisplayed = @"PlaySRGSettingAudioDescriptionAvailabilityDisplayed";
NSString * const PlaySRGSettingDiscoverySubtitleOptionLanguageRunOnce = @"PlaySRGSettingDiscoverySubtitleOptionLanguageRunOnce";
NSString * const PlaySRGSettingLastLoggedInEmailAddress = @"PlaySRGSettingLastLoggedInEmailAddress";
NSString * const PlaySRGSettingSelectedLivestreamURNForChannels = @"PlaySRGSettingSelectedLivestreamURNForChannels";
NSString * const PlaySRGSettingServiceIdentifier = @"PlaySRGSettingServiceIdentifier";
NSString * const PlaySRGSettingUserLocation = @"PlaySRGSettingUserLocation";
NSString * const PlaySRGSettingUserConsentAcceptedServiceIds = @"PlaySRGSettingUserConsentAcceptedServiceIds";
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
NSString * const PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled = @"PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled";
#endif

__attribute__((constructor)) static void ApplicationSettingsConstantsInit(void)
{
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    [userDefaults registerDefaults:@{ PlaySRGSettingHDOverCellularEnabled : @YES,
                                      PlaySRGSettingPresenterModeEnabled : @NO,
                                      PlaySRGSettingStandaloneEnabled : @NO,
                                      PlaySRGSettingAutoplayEnabled : @YES,
                                      PlaySRGSettingBackgroundVideoPlaybackEnabled : @NO }];
    [userDefaults synchronize];
}
