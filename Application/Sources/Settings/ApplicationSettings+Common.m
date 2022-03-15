//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSettings+Common.h"

#import "ApplicationSettingsConstants.h"
#if TARGET_OS_IOS
#import "PlayApplication.h"
#endif

@import Mantle;
@import SRGDataProvider;

/**
 *  User location options.
 */
typedef NS_ENUM(NSInteger, SettingUserLocation) {
    /**
     *  Default IP-based location.
     */
    SettingUserLocationDefault,
    /**
     *  Outside CH.
     */
    SettingUserLocationOutsideCH,
    /**
     *  Ignore location.
     */
    SettingUserLocationIgnored
};

NSString * const PlaySRGSettingProgramGuideRecentlyUsedLayout = @"PlaySRGSettingProgramGuideRecentlyUsedLayout";
NSString * const PlaySRGSettingLastSelectedPlaybackRate = @"PlaySRGSettingLastSelectedPlaybackRate";
NSString * const PlaySRGSettingLastSelectedAudioLanguageCode = @"PlaySRGSettingLastSelectedAudioLanguageCode";

NSValueTransformer *ProgramGuideLayoutTransformer(void)
{
    static NSValueTransformer *s_transformer;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{ @"grid" : @(ProgramGuideLayoutGrid),
                                                                                         @"list" : @(ProgramGuideLayoutList) }
                                                                         defaultValue:@(ProgramGuideLayoutGrid)
                                                                  reverseDefaultValue:nil];
    });
    return s_transformer;
}

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

ProgramGuideLayout ApplicationSettingProgramGuideRecentlyUsedLayout(void)
{
    return [[ProgramGuideLayoutTransformer() transformedValue:[NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingProgramGuideRecentlyUsedLayout]] integerValue];
}

void ApplicationSettingSetProgramGuideRecentlyUsedLayout(ProgramGuideLayout layout)
{
    NSString *layoutIdentifier = [ProgramGuideLayoutTransformer() reverseTransformedValue:@(layout)];
    
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    [userDefaults setObject:layoutIdentifier forKey:PlaySRGSettingProgramGuideRecentlyUsedLayout];
    [userDefaults synchronize];
}

BOOL ApplicationSettingSectionWideSupportEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingSectionWideSupportEnabled];
}

NSValueTransformer *SettingPosterImagesTransformer(void)
{
    static NSValueTransformer *s_transformer;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{ @"forced" : @(SettingPosterImagesForced),
                                                                                         @"ignored" : @(SettingPosterImagesIgnored) }
                                                                         defaultValue:@(SettingPosterImagesDefault)
                                                                  reverseDefaultValue:nil];
    });
    return s_transformer;
}

SettingPosterImages ApplicationSettingPosterImages(void)
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    return [[SettingPosterImagesTransformer() transformedValue:[NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingPosterImages]] integerValue];
#else
    return SettingPosterImagesDefault;
#endif
}

NSURL *ApplicationSettingServiceURL(void)
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
#if TARGET_OS_IOS
    __block BOOL settingServiceURLReset = YES;
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        settingServiceURLReset = NO;
        completionHandler(YES);
    }, @"SettingServiceURLReset2");
    
    if (! settingServiceURLReset) {
        [userDefaults removeObjectForKey:PlaySRGSettingServiceURL];
        [userDefaults synchronize];
    }
#endif
    // Do not use `-URLForKey:`, as the method transform the string to a file URL.
    NSString *URLString = [userDefaults stringForKey:PlaySRGSettingServiceURL];
    NSURL *URL = URLString ? [NSURL URLWithString:URLString] : nil;
    return URL ?: SRGIntegrationLayerProductionServiceURL();
#else
    return SRGIntegrationLayerProductionServiceURL();
#endif
}

void ApplicationSettingSetServiceURL(NSURL *serviceURL)
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    // Do not use `-setURL:forKey:`, as the method archives the value, preventing InAppSettingsKit from comparing it
    // to a selectable value. `-URLForKey:` can't be used when reading, though.
    [userDefaults setObject:serviceURL.absoluteString forKey:PlaySRGSettingServiceURL];
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

float ApplicationSettingLastSelectedPlaybackRate(void)
{
    NSNumber *playbackRate = [NSUserDefaults.standardUserDefaults objectForKey:PlaySRGSettingLastSelectedPlaybackRate];
    return playbackRate ? playbackRate.floatValue : 1.f;
}

void ApplicationSettingSetLastSelectedPlaybackRate(float playbackRate)
{
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    [userDefaults setFloat:playbackRate forKey:PlaySRGSettingLastSelectedPlaybackRate];
    [userDefaults synchronize];
}

NSString *ApplicationSettingLastSelectedAudioLanguageCode(void)
{
    return [NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingLastSelectedAudioLanguageCode];
}

void ApplicationSettingSetLastSelectedAudioLanguageCode(NSString *languageCode)
{
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    [userDefaults setObject:languageCode forKey:PlaySRGSettingLastSelectedAudioLanguageCode];
    [userDefaults synchronize];
}
