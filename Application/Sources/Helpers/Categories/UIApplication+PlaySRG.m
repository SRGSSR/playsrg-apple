//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIApplication+PlaySRG.h"

#import "UIWindow+PlaySRG.h"

@import SafariServices;

@implementation UIApplication (PlaySRG)

- (void)play_openURL:(NSURL *)URL withCompletionHandler:(void (^)(BOOL))completion
{
    [self openURL:URL options:@{} completionHandler:completion];
}

@end
