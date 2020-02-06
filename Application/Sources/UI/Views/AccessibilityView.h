//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AccessibilityView;

@protocol AccessibilityViewDelegate <NSObject>

- (nullable NSString *)labelForAccessibilityView:(AccessibilityView *)accessibilityView;
- (nullable NSString *)hintForAccessibilityView:(AccessibilityView *)accessibilityView;

@end

@interface AccessibilityView : UIView

@property (nonatomic, weak) IBOutlet id<AccessibilityViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
