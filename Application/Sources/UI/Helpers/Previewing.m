//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

#import <CoconutKit/CoconutKit.h>

static void *s_contextMenuInteraction = &s_contextMenuInteraction;
static void *s_previewContextViewControllerKey = &s_previewContextViewControllerKey;
static void *s_previewingHandleKey = &s_previewingHandleKey;

@interface UIView (PreviewingPrivate)

@property (nonatomic, weak) UIContextMenuInteraction *contextMenuInteraction API_AVAILABLE(ios(13.0));

@property (nonatomic, weak) UIViewController *previewContextViewController;
@property (nonatomic) id<UIViewControllerPreviewing> previewingHandle;

@end

@implementation UIView (Previewing)

#pragma mark Class methods

+ (void)play_updatePreviewRegistrationsInView:(UIView *)view
{
    if (view.previewingHandle) {
        [view play_registerForPreview];
    }
    
    for (UIView *subview in view.subviews) {
        [self play_updatePreviewRegistrationsInView:subview];
    }
}

#pragma mark Getters and setters

- (UIContextMenuInteraction *)contextMenuInteraction
{
    return hls_getAssociatedObject(self, s_contextMenuInteraction);
}

- (void)setContextMenuInteraction:(UIContextMenuInteraction *)contextMenuInteraction
{
    hls_setAssociatedObject(self, s_contextMenuInteraction, contextMenuInteraction, HLS_ASSOCIATION_WEAK_NONATOMIC);
}

- (UIViewController *)previewContextViewController
{
    return hls_getAssociatedObject(self, s_previewContextViewControllerKey);
}

- (void)setPreviewContextViewController:(UIViewController *)previewContextViewController
{
    hls_setAssociatedObject(self, s_previewContextViewControllerKey, previewContextViewController, HLS_ASSOCIATION_WEAK_NONATOMIC);
}

- (id<UIViewControllerPreviewing>)previewingHandle
{
    return objc_getAssociatedObject(self, s_previewingHandleKey);
}

- (void)setPreviewingHandle:(id<UIViewControllerPreviewing>)previewingHandle
{
    objc_setAssociatedObject(self, s_previewingHandleKey, previewingHandle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController<PreviewingDelegate> *)play_previewingDelegate
{
    UIResponder *responder = self.nextResponder;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]] && [responder conformsToProtocol:@protocol(PreviewingDelegate)]) {
            return (UIViewController<PreviewingDelegate> *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

- (UIViewController<UIContextMenuInteractionDelegate> *)play_contextMenuInteractionDelegate API_AVAILABLE(ios(13.0))
{
    UIResponder *responder = self.nextResponder;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]] && [responder conformsToProtocol:@protocol(UIContextMenuInteractionDelegate)]) {
            return (UIViewController<UIContextMenuInteractionDelegate> *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

#pragma mark Registration

- (void)play_registerForPreview
{
    if (@available(iOS 13, *)) {
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
    else {
        if (self.previewingHandle) {
            [self.previewContextViewController unregisterForPreviewingWithContext:self.previewingHandle];
        }
        
        UIViewController<PreviewingDelegate> *previewingDelegate = [self play_previewingDelegate];
        if (previewingDelegate) {
            UIViewController *previewContextViewController = previewingDelegate.previewContextViewController;
            self.previewingHandle = [previewContextViewController registerForPreviewingWithDelegate:previewingDelegate sourceView:self];
            self.previewContextViewController = previewContextViewController;
        }
    }
}

@end
