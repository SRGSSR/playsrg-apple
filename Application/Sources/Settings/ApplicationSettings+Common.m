//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSettings+Common.h"

#import "ApplicationSettingsConstants.h"
#import "PlaySRG-Swift.h"

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

ProgramGuideLayout ApplicationSettingProgramGuideRecentlyUsedLayout(BOOL isCompactHorizontalSizeClass)
{
    NSString *layoutIdentifier = [NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingProgramGuideRecentlyUsedLayout];
    if (layoutIdentifier) {
        return [[ProgramGuideLayoutTransformer() transformedValue:layoutIdentifier] integerValue];
    }
    else if (isCompactHorizontalSizeClass) {
        return ProgramGuideLayoutList;
    }
    else {
        return ProgramGuideLayoutGrid;
    }
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

NSValueTransformer *SettingSquareImagesTransformer(void)
{
    static NSValueTransformer *s_transformer;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{ @"forced" : @(SettingSquareImagesForced),
                                                                                         @"ignored" : @(SettingSquareImagesIgnored) }
                                                                         defaultValue:@(SettingSquareImagesDefault)
                                                                  reverseDefaultValue:nil];
    });
    return s_transformer;
}

SettingSquareImages ApplicationSettingSquareImages(void)
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    return [[SettingSquareImagesTransformer() transformedValue:[NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingSquareImages]] integerValue];
#else
    return SettingSquareImagesDefault;
#endif
}

NSValueTransformer *SettingAudioHomepageOptionTransformer(void)
{
    static NSValueTransformer *s_transformer;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{ @"curatedOne" : @(SettingAudioHomepageOptionCuratedOne),
                                                                                         @"curatedMany" : @(SettingAudioHomepageOptionCuratedMany),
                                                                                         @"predefinedMany" : @(SettingAudioHomepageOptionPredefinedMany) }
                                                                         defaultValue:@(SettingAudioHomepageOptionDefault)
                                                                  reverseDefaultValue:nil];
    });
    return s_transformer;
}

SettingAudioHomepageOption ApplicationSettingAudioHomepageOption(void)
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    return [[SettingAudioHomepageOptionTransformer() transformedValue:[NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingAudioHomepageOption]] integerValue];
#else
    return SettingAudioHomepageOptionDefault;
#endif
}

NSDictionary<NSString *, NSString *> *ApplicationSettingGlobalParameters(void)
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSMutableDictionary<NSString *, NSString *> *globalParameters = [NSMutableDictionary dictionary];
    
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_locations;
    dispatch_once(&s_onceToken, ^{
        s_locations = @{ @(SettingUserLocationOutsideCH) : @"WW",
                         @(SettingUserLocationIgnored) : @"CH" };
    });
    
    SettingUserLocation userLocation = [[SettingUserLocationTransformer() transformedValue:[NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingUserLocation]] integerValue];
    NSString *location = s_locations[@(userLocation)];
    if (location) {
        globalParameters[@"forceLocation"] = location;
    }
    
    BOOL forceSAM = [ApplicationSettingServiceIdentifier().lowercaseString containsString:@"sam"];
    if (forceSAM) {
        globalParameters[@"forceSAM"] = @"true";
    }
    
    return globalParameters.count > 0 ? globalParameters.copy : nil;
#else
    return nil;
#endif
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

NSString *ApplicationSettingServiceIdentifier(void)
{
    return [NSUserDefaults.standardUserDefaults stringForKey:PlaySRGSettingServiceIdentifier];
}

void ApplicationSettingSetServiceIdentifier(NSString *identifier)
{
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    [userDefaults setObject:identifier forKey:PlaySRGSettingServiceIdentifier];
    [userDefaults synchronize];
}

NSURL *ApplicationSettingServiceURL(void)
{
    return [ServiceObjC urlFor:ApplicationSettingServiceIdentifier()];
}

BOOL ApplicationSettingAutoplayEnabled(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingAutoplayEnabled];
}

BOOL ApplicationSettingDiscoverySubtitleOptionLanguageRunOnce(void)
{
    return [NSUserDefaults.standardUserDefaults boolForKey:PlaySRGSettingDiscoverySubtitleOptionLanguageRunOnce];
}

void ApplicationSettingSetDiscoverySubtitleOptionLanguageRunOnce(BOOL discoverySubtitleOptionLanguageRunOnce)
{
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    [userDefaults setBool:discoverySubtitleOptionLanguageRunOnce forKey:PlaySRGSettingDiscoverySubtitleOptionLanguageRunOnce];
    [userDefaults synchronize];
}
