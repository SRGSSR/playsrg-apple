//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (PlaySRG)

- (void)play_openURL:(NSURL*)URL withCompletionHandler:(void (^ __nullable)(BOOL success))completion NS_EXTENSION_UNAVAILABLE_IOS("No Safari web view and open URL method in iOS extension.");

@end

NS_ASSUME_NONNULL_END
