//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

#import <CoconutKit/CoconutKit.h>

static void *s_previewContextViewControllerKey = &s_previewContextViewControllerKey;
static void *s_previewingHandleKey = &s_previewingHandleKey;

@interface UIView (PreviewingPrivate)

@property (nonatomic, weak) UIViewController *previewContextViewController;
@property (nonatomic) id<UIViewControllerPreviewing> previewingHandle;

@end

@implementation UIView (Previewing)

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

+ (void)play_updatePreviewRegistrationsInView:(UIView *)view
{
    if (view.previewingHandle) {
        [view play_registerForPreview];
    }
    
    for (UIView *subview in view.subviews) {
        [self play_updatePreviewRegistrationsInView:subview];
    }
}

- (void)play_registerForPreview
{
    UIViewController<PreviewingDelegate> *previewingDelegate = [self play_previewingDelegate];
    if (self.previewingHandle) {
        [self.previewContextViewController unregisterForPreviewingWithContext:self.previewingHandle];
    }
    
    UIViewController *previewContextViewController = previewingDelegate.previewContextViewController;
    self.previewingHandle = [previewContextViewController registerForPreviewingWithDelegate:previewingDelegate sourceView:self];
    self.previewContextViewController = previewContextViewController;
}

@end
