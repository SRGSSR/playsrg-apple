//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Mantle;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface OnboardingPage : MTLModel <MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSString *uid;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *text;

@property (nonatomic, readonly) UIColor *color;

@end

NS_ASSUME_NONNULL_END
