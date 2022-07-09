//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return an accessibility-oriented localized string from the main bundle.
 */
OBJC_EXPORT NSString *PlaySRGAccessibilityLocalizedString(NSString *key, NSString * _Nullable comment) NS_REFINED_FOR_SWIFT;

/**
 *  Return an onboarding localized string from the main bundle.
 */
OBJC_EXPORT NSString *PlaySRGOnboardingLocalizedString(NSString *key, NSString * _Nullable comment) NS_REFINED_FOR_SWIFT;

/**
 *  Use to avoid user-facing text analyzer warnings.
 *
 *  See https://clang-analyzer.llvm.org/faq.html.
 */
__attribute__((annotate("returns_localized_nsstring")))
OBJC_EXPORT NSString *PlaySRGNonLocalizedString(NSString *string);

@interface NSBundle (PlaySRG)

@property (nonatomic, readonly) NSString *play_friendlyVersionNumber;

@end

NS_ASSUME_NONNULL_END
