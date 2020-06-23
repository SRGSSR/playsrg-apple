//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "GradientView.h"

static void commonInit(GradientView *self);

@interface GradientView ()

@property (nonatomic, weak) CAGradientLayer *gradientLayer;

@end

@implementation GradientView

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.gradientLayer.frame = self.bounds;
    [CATransaction commit];
}

#pragma mark Gradient

- (void)updateWithStartColor:(UIColor *)startColor atPoint:(CGPoint)startPoint endColor:(UIColor *)endColor atPoint:(CGPoint)endPoint animated:(BOOL)animated
{
    void (^update)(void) = ^{
        UIColor *fromColor = startColor ?: self.backgroundColor;
        UIColor *toColor = endColor ?: self.backgroundColor;
        
        self.gradientLayer.colors = @[ (id)fromColor.CGColor, (id)toColor.CGColor ];
        self.gradientLayer.startPoint = startPoint;
        self.gradientLayer.endPoint = endPoint;
    };
    
    if (animated) {
        update();
    }
    else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        update();
        [CATransaction commit];
    }
}

@end

static void commonInit(GradientView *self)
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    [self.layer insertSublayer:gradientLayer atIndex:0];
    self.gradientLayer = gradientLayer;
}
