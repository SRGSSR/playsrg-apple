//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayApplication.h"

static NSString * const PlayApplicationRunOnceDictionaryKey = @"PlaySRGPlayApplicationRunOnce";

void PlayApplicationRunOnce(void (NS_NOESCAPE ^block)(void (^completionHandler)(BOOL success)), NSString *key, id object)
{
    NSCParameterAssert(block);
    NSCParameterAssert(key);
    
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    NSMutableDictionary *runOnceDictionary = [[userDefaults objectForKey:PlayApplicationRunOnceDictionaryKey] mutableCopy] ?: [NSMutableDictionary dictionary];
    
    id existingObject = runOnceDictionary[key];
    
    if (! existingObject || (object && ! [existingObject isEqual:object])) {
        void (^completionHandler)(BOOL success) = ^(BOOL success) {
            if (success) {
                runOnceDictionary[key] = object ?: @YES;
                [userDefaults setObject:runOnceDictionary.copy forKey:PlayApplicationRunOnceDictionaryKey];
                [userDefaults synchronize];
            }
        };
        block(completionHandler);
    }
}

id PlayApplicationRunOnceObjectForKey(NSString *key)
{
    NSDictionary *runOnceDictionary = [NSUserDefaults.standardUserDefaults objectForKey:PlayApplicationRunOnceDictionaryKey];
    return runOnceDictionary[key];
}
