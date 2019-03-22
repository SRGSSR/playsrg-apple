//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LiveAccessButton.h"

#import "ApplicationConfiguration.h"
#import "NSBundle+PlaySRG.h"

#import <Masonry/Masonry.h>

@interface LiveAccessButton ()

@property (nonatomic, weak) UIImageView *internalImageView;
@property (nonatomic, weak) CALayer *highlightingLayer;

@property (nonatomic, weak) CALayer *leftSeparatorLayer;
@property (nonatomic, weak) CALayer *rightSeparatorLayer;

@property (nonatomic) UIColor *savedBackgroundColor;

@end

static void commonInit(LiveAccessButton *self)
{
    UIImageView *internalImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"radioset-44"]];
    internalImageView.tintColor = UIColor.whiteColor;
    internalImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:internalImageView];
    self.internalImageView = internalImageView;
    
    CGColorRef separatorColor = [UIColor colorWithWhite:1.f alpha:0.2f].CGColor;
    
    CALayer *leftSeparatorLayer = [CALayer layer];
    leftSeparatorLayer.backgroundColor = separatorColor;
    [self.layer addSublayer:leftSeparatorLayer];
    self.leftSeparatorLayer = leftSeparatorLayer;
    
    CALayer *rightSeparatorLayer = [CALayer layer];
    rightSeparatorLayer.backgroundColor = separatorColor;
    [self.layer addSublayer:rightSeparatorLayer];
    self.rightSeparatorLayer = rightSeparatorLayer;
}

@implementation LiveAccessButton

#pragma mark Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Getters and setters

- (BOOL)isLeftSeparatorHidden
{
    return self.leftSeparatorLayer.hidden;
}

- (void)setLeftSeparatorHidden:(BOOL)leftSeparatorHidden
{
    self.leftSeparatorLayer.hidden = leftSeparatorHidden;
}

- (BOOL)isRightSeparatorHidden
{
    return self.rightSeparatorLayer.hidden;
}

- (void)setRightSeparatorHidden:(BOOL)rightSeparatorHidden
{
    self.rightSeparatorLayer.hidden = rightSeparatorHidden;
}

- (void)setMedia:(SRGMedia *)media
{
    _media = media;
    RadioChannel *radioChannel = [ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:self.media.channel.uid];
    self.internalImageView.image = RadioChannelLogo44Image(radioChannel);
}

#pragma mark Overrides

- (void)setSelected:(BOOL)selected
{
    super.selected = selected;
    
    if (selected) {
        if (!self.highlightingLayer) {
            CALayer *highlightingLayer = [CALayer layer];
            highlightingLayer.cornerRadius = 2.f;
            highlightingLayer.backgroundColor = UIColor.whiteColor.CGColor;
            [self.layer addSublayer:highlightingLayer];
            self.highlightingLayer = highlightingLayer;
        }
    }
    else {
        [self.highlightingLayer removeFromSuperlayer];
    }
    
    [self layoutIfNeeded];
    
    self.userInteractionEnabled = !selected;
}

- (void)setHighlighted:(BOOL)highlighted
{
    super.highlighted = highlighted;
    UIColor *savedBackgroundColor = self.savedBackgroundColor;
    if (self.highlightedBackgroundColor) {
        self.backgroundColor = (highlighted) ? self.highlightedBackgroundColor : self.savedBackgroundColor;
        self.savedBackgroundColor = savedBackgroundColor;
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    super.backgroundColor = backgroundColor;
    self.savedBackgroundColor = backgroundColor;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    // Only set constraints when the view is installed. Buttons are usually instantiated with a zero frame, which leads
    // to breaking constraints when margins have been specified
    if (newWindow) {
        [self.internalImageView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(10.f, 6.f, 10.f, 6.f));
        }];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    static const CGFloat kHorizontalFillFactor = 0.7f;
    static const CGFloat kVerticalFillFactor = 0.65f;
    static const CGFloat kSpacerWidth = 2.f;
    
    self.highlightingLayer.frame = CGRectMake((1.f - kHorizontalFillFactor) * CGRectGetWidth(self.frame) / 2.f,
                                              0.f,
                                              kHorizontalFillFactor * CGRectGetWidth(self.frame),
                                              3.f);
    
    CGFloat separatorYPos = (1.f - kVerticalFillFactor) * CGRectGetHeight(self.frame) / 2.f;
    CGFloat separatorHeight = kVerticalFillFactor * CGRectGetHeight(self.frame);
    self.leftSeparatorLayer.frame = CGRectMake(0.f,
                                               separatorYPos,
                                               kSpacerWidth/2,
                                               separatorHeight);
    self.rightSeparatorLayer.frame = CGRectMake(CGRectGetWidth(self.frame) - kSpacerWidth/2,
                                                separatorYPos,
                                                kSpacerWidth/2,
                                                separatorHeight);
}

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    return [NSString stringWithFormat:PlaySRGAccessibilityLocalizedString(@"%@ live", @"Live content label, with a media title"), self.media.title];
}

- (NSString *)accessibilityHint
{
    return PlaySRGAccessibilityLocalizedString(@"Plays livestream.", @"Livestream play action hint");
}

- (UIAccessibilityTraits)accessibilityTraits
{
    // Treat each live access button as a header for quick navigation
    return UIAccessibilityTraitHeader;
}

@end
