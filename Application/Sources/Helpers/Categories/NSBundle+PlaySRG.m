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
    
    NSString *buildName = [NSBundle.mainBundle.infoDictionary objectForKey:@"BuildName"];
    NSString *bundleNameSuffix = [NSBundle.mainBundle.infoDictionary objectForKey:@"BundleNameSuffix"];
    NSString *friendlyBuildName = [NSString stringWithFormat:@"%@%@",
                                   buildName.length > 0 ? [@" " stringByAppendingString:buildName] : @"",
                                   bundleNameSuffix.length > 0 ? [@" " stringByAppendingString:bundleNameSuffix] : @""];
    
    NSString *version = [NSString stringWithFormat:@"%@ (%@)%@", marketingVersion, bundleVersion, friendlyBuildName];
    if ([self play_isTestFlightDistribution]) {
        // Unbreakable spaces before / after the separator
        version = [version stringByAppendingString:@" - TF"];
    }
    return version;
}

- (BOOL)play_isTestFlightDistribution
{
#if !defined(DEBUG)
    return (self.appStoreReceiptURL.path && [self.appStoreReceiptURL.path rangeOfString:@"sandboxReceipt"].location != NSNotFound);
#else
    return NO;
#endif
}

@end
