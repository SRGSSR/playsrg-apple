//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSBundle+PlaySRG.h"

NSString *PlaySRGAccessibilityLocalizedString(NSString *key, __unused NSString *comment)
{
    return [NSBundle.mainBundle localizedStringForKey:key value:@"" table:@"Accessibility"];
}

NSString *PlaySRGOnboardingLocalizedString(NSString *key, __unused NSString *comment)
{
    return [NSBundle.mainBundle localizedStringForKey:key value:@"" table:@"Onboarding"];
}

NSString *PlaySRGSettingsLocalizedString(NSString *key, __unused NSString *comment)
{
#if TARGET_OS_IOS
    NSString *settingsBundlePath = [NSBundle.mainBundle pathForResource:@"Settings" ofType:@"bundle"];
    return [[NSBundle bundleWithPath:settingsBundlePath] localizedStringForKey:key value:@"" table:@"Settings"];
#else
    return [NSBundle.mainBundle localizedStringForKey:key value:@"" table:@"Settings"];
#endif
}

NSString *PlaySRGNonLocalizedString(NSString *string)
{
    return string;
}

@implementation NSBundle (PlaySRG)

- (NSString *)play_friendlyVersionNumber
{
    NSString *shortVersionString = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *marketingVersion = [shortVersionString componentsSeparatedByString:@"-"].firstObject ?: shortVersionString;
    
    NSString *bundleVersion = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleVersion"];
    
    NSString *bundleDisplayNameSuffix = [NSBundle.mainBundle.infoDictionary objectForKey:@"BundleDisplayNameSuffix"];
    NSString *buildName = [NSBundle.mainBundle.infoDictionary objectForKey:@"BuildName"];
    NSString *friendlyBuildName = [NSString stringWithFormat:@"%@%@",
                                   bundleDisplayNameSuffix.length > 0 ? bundleDisplayNameSuffix : @"",
                                   buildName.length > 0 ? [@" " stringByAppendingString:buildName] : @""];
    
    NSString *version = [NSString stringWithFormat:@"%@ (%@)%@", marketingVersion, bundleVersion, friendlyBuildName];
    if ([self play_isTestFlightDistribution]) {
        // Unbreakable spaces before / after the separator
        version = [version stringByAppendingString:@" - TF"];
    }
    return version;
}

- (BOOL)play_isTestFlightDistribution
{
#if !defined(DEBUG) && !defined(APPCENTER)
    return (self.appStoreReceiptURL.path && [self.appStoreReceiptURL.path rangeOfString:@"sandboxReceipt"].location != NSNotFound);
#else
    return NO;
#endif
}

@end
