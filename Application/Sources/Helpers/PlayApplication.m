//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayApplication.h"

static NSString * const PlayApplicationRunOnceDictionaryKey = @"PlaySRGPlayApplicationRunOnce";

void PlayApplicationRunOnce(void (NS_NOESCAPE ^block)(void (^completionHandler)(BOOL success)), NSString *key)
{
    NSCParameterAssert(block);
    NSCParameterAssert(key);
    
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    NSMutableDictionary *runOnceDictionary = [[userDefaults objectForKey:PlayApplicationRunOnceDictionaryKey] mutableCopy] ?: [NSMutableDictionary dictionary];
    
    if (! runOnceDictionary[key]) {
        void (^completionHandler)(BOOL success) = ^(BOOL success) {
            if (success) {
                runOnceDictionary[key] = @YES;
                [userDefaults setObject:runOnceDictionary.copy forKey:PlayApplicationRunOnceDictionaryKey];
                [userDefaults synchronize];
            }
        };
        block(completionHandler);
    }
}
