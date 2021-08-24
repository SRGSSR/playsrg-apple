//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DeepLinkService.h"

@import StoreKit;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : UIResponder <SKStoreProductViewControllerDelegate, UIApplicationDelegate>

@property (nonatomic, readonly) DeepLinkService *deepLinkService;

@end

NS_ASSUME_NONNULL_END

