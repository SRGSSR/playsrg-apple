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
    }, @"SettingServiceURLReset2", nil);
    
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
