//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GradientView : UIView

/**
 *  Draw a gradient between the two specified points.
 *
 *  @discussion If a color is `nil`, the current view background color is used instead.
 */
- (void)updateWithStartColor:(nullable UIColor *)startColor atPoint:(CGPoint)startPoint
                    endColor:(nullable UIColor *)endColor atPoint:(CGPoint)endPoint
                    animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
