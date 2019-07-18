//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UISearchBar+PlaySRG.h"

static __kindof UIView *SearchBarSubviewOfClass(UIView *view, Class cls)
{
    if ([view isKindOfClass:cls]) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIView *classView = SearchBarSubviewOfClass(subview, cls);
        if (classView) {
            return classView;
        }
    }
    
    return nil;
}

@implementation UISearchBar (PlaySRG)

#pragma mark Getters and setters

- (UITextField *)play_textField
{
    return SearchBarSubviewOfClass(self, UITextField.class);
}

- (UIButton *)play_bookmarkButton
{
    return SearchBarSubviewOfClass(self.play_textField, UIButton.class);
}

@end
