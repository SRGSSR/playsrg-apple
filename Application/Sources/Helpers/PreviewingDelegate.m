//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PreviewingDelegate.h"

@import libextobjc;

static void *s_kvoContext = &s_kvoContext;

@interface PreviewingDelegate ()

@property (nonatomic, weak) id<PreviewingDelegate> realDelegate;

@end

@implementation PreviewingDelegate

#pragma mark Object lifecycle

- (instancetype)initWithRealDelegate:(id<PreviewingDelegate>)realDelegate
{
    if (self = [super init]) {
        self.realDelegate = realDelegate;
    }
    return self;
}

#pragma mark PreviewingDelegate protocol

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    [self.realDelegate handleLongPress:gestureRecognizer];
}

- (UIViewController *)previewContextViewController
{
    return self.realDelegate.previewContextViewController;
}

#pragma mark UIViewControllerPreviewingDelegate protocol

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    // Observe gesture recognizer state do detect whether a peek is followed by a pop or cancelled
    // See http://stackoverflow.com/questions/35705799/3d-touch-calls-viewdiddisappear-when-popping-vc
    UIGestureRecognizer *peekGestureRecognizer = previewingContext.previewingGestureRecognizerForFailureRelationship;
    [peekGestureRecognizer addObserver:self
                            forKeyPath:@keypath(peekGestureRecognizer.state)
                               options:NSKeyValueObservingOptionNew
                               context:s_kvoContext];
    return [self.realDelegate previewingContext:previewingContext viewControllerForLocation:location];
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    [self.realDelegate previewingContext:previewingContext commitViewController:viewControllerToCommit];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == s_kvoContext) {
        if ([keyPath isEqualToString:@keypath(UIGestureRecognizer.new, state)]) {
            NSInteger state = [change[NSKeyValueChangeNewKey] integerValue];
            
            switch (state) {
                case UIGestureRecognizerStateBegan:
                case UIGestureRecognizerStateChanged: {
                    break;
                }
                    
                case UIGestureRecognizerStateEnded:
                case UIGestureRecognizerStateFailed:
                case UIGestureRecognizerStateCancelled: {
                    [object removeObserver:self forKeyPath:@keypath(UIGestureRecognizer.new, state) context:s_kvoContext];
                    break;
                }
                    
                default: {
                    break;
                }
            }
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
