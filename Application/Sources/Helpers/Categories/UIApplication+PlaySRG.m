//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIApplication+PlaySRG.h"

#import "UIColor+PlaySRG.h"
#import "UIWindow+PlaySRG.h"

#import <SafariServices/SafariServices.h>

@implementation UIApplication (PlaySRG)

- (void)play_openURL:(NSURL *)URL withCompletionHandler:(void (^)(BOOL))completion
{
    void (^openCompletion)(NSURL *) = ^(NSURL *URL) {
        if ([URL.scheme isEqualToString:@"https"] || [URL.scheme isEqualToString:@"http"]) {
            SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:URL];
            safariViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            if (@available(iOS 10, *)) {
                safariViewController.preferredBarTintColor = UIColor.play_blackColor;
                safariViewController.preferredControlTintColor = UIColor.whiteColor;
            }
            [self.keyWindow.play_topViewController presentViewController:safariViewController animated:YES completion:nil];
            completion ? completion(YES) : nil;
        }
        else if ([self canOpenURL:URL]) {
            [self openURL:URL];
            completion ? completion(YES) : nil;
        }
        else {
            completion ? completion(NO) : nil;
        }
    };
    
    if (@available(iOS 10, *)) {
        [self openURL:URL options:@{ UIApplicationOpenURLOptionUniversalLinksOnly : @YES } completionHandler:^(BOOL success) {
            if (success) {
                completion ? completion(YES) : nil;
            }
            else {
                openCompletion(URL);
            }
        }];
    }
    else {
        openCompletion(URL);
    }
}

@end
