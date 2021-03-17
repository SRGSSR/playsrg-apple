//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

#import <objc/runtime.h>

static void *s_contextMenuInteraction = &s_contextMenuInteraction;

@interface UIView (PreviewingPrivate)

@property (nonatomic, weak) UIContextMenuInteraction *contextMenuInteraction;

@end

@implementation UIView (Previewing)

#pragma mark Getters and setters

- (UIContextMenuInteraction *)contextMenuInteraction
{
    return [objc_getAssociatedObject(self, s_contextMenuInteraction) nonretainedObjectValue];
}

- (void)setContextMenuInteraction:(UIContextMenuInteraction *)contextMenuInteraction
{
    objc_setAssociatedObject(self, s_contextMenuInteraction, [NSValue valueWithNonretainedObject:contextMenuInteraction], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController<UIContextMenuInteractionDelegate> *)play_contextMenuInteractionDelegate
{
    UIResponder *responder = self.nextResponder;
    while (responder) {
        if ([responder isKindOfClass:UIViewController.class] && [responder conformsToProtocol:@protocol(UIContextMenuInteractionDelegate)]) {
            return (UIViewController<UIContextMenuInteractionDelegate> *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

#pragma mark Registration

- (void)play_registerForPreview
{
    if (self.contextMenuInteraction) {
        [self removeInteraction:self.contextMenuInteraction];
    }
    
    UIViewController<UIContextMenuInteractionDelegate> *contextMenuInteractionDelegate = [self play_contextMenuInteractionDelegate];
    if (contextMenuInteractionDelegate) {
        UIContextMenuInteraction *contextMenuInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:contextMenuInteractionDelegate];
        [self addInteraction:contextMenuInteraction];
        self.contextMenuInteraction = contextMenuInteraction;
    }
}

@end
