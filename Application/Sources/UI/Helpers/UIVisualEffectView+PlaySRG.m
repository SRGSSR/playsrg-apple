//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIVisualEffectView+PlaySRG.h"

@implementation UIVisualEffectView (PlaySRG)

#pragma mark Class methods

+ (UIVisualEffectView *)play_blurView
{
    UIBlurEffectStyle blurEffectStyle;
    blurEffectStyle = UIBlurEffectStyleSystemMaterialDark;
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:blurEffectStyle];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.backgroundColor = nil;
    return blurView;
}

@end
