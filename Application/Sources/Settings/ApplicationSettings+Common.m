//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSettings+Common.h"

#import "ApplicationSettingsConstants.h"

@import Mantle;

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
