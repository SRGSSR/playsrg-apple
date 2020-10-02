//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

#if TARGET_OS_TV

#import <objc/runtime.h>

@interface NSObject (FirebaseRemoteConfigStorageFix)

+ (NSString *)swizzled_remoteConfigPathForDatabase;

@end

@implementation NSObject (FirebaseRemoteConfigStorageFix)

+ (void)load
{
    // Fix RCN000019 Firebase Remote Configuration issue on an Apple TV device, for which only few directories
    // can be written (https://developer.apple.com/library/archive/documentation/General/Conceptual/AppleTV_PG/).
    Class clazz = NSClassFromString(@"RCNConfigDBManager");
    NSAssert(clazz != NULL, @"The Firebase SDK implementation changed");
    
    Method originalMethod = class_getClassMethod(clazz, NSSelectorFromString(@"remoteConfigPathForDatabase"));
    NSAssert(originalMethod != NULL, @"The Firebase SDK implementation changed");
    method_exchangeImplementations(originalMethod,
                                   class_getClassMethod(clazz, @selector(swizzled_remoteConfigPathForDatabase)));
}

+ (NSString *)swizzled_remoteConfigPathForDatabase
{
    NSString *cachesDirectoryPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    return [cachesDirectoryPath stringByAppendingPathComponent:@"Google/RemoteConfig/RemoteConfig.sqlite3"];
}

@end

#endif
