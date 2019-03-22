//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayApplication.h"

void PlayApplicationRunOnce(void (^block)(void (^completionHandler)(BOOL success)), NSString *key, id object)
{
    NSCParameterAssert(block);
    NSCParameterAssert(key);
    
    static NSString * const PlayApplicationRunOnceDictionaryKey = @"PlaySRGPlayApplicationRunOnce";
    
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    NSMutableDictionary *runOnceDictionary = [[userDefaults objectForKey:PlayApplicationRunOnceDictionaryKey] mutableCopy] ?: [NSMutableDictionary dictionary];
    
    void (^completionHandler)(BOOL success) = ^(BOOL success) {
        if (success) {
            runOnceDictionary[key] = object ?: @YES;
            [userDefaults setObject:[runOnceDictionary copy] forKey:PlayApplicationRunOnceDictionaryKey];
            [userDefaults synchronize];
        }
    };
    
    id existingObject = runOnceDictionary[key];
    
    if (!existingObject || (object && ![existingObject isEqual:object])) {
        block(completionHandler);
    }
}
