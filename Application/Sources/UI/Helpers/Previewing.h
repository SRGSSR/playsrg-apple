//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

/**
 *  Protocol to be used by source views to setup associated peek-and-pop behavior
 */
@protocol Previewing <NSObject>

/**
 *  The preview object attached to the source view
 */
@property (nonatomic, readonly) id previewObject;

@end

/**
 *  Protocol to be implemented by view controllers which want to register for pseudo 3D Touch support without real device
 *  support. No peek and pop is implemented, only an action is triggered when a long press is detected
 */
@protocol LegacyPreviewingSupport <NSObject>

/**
 *  Method which gets called when a long press is detected on a view conforming to the `Previewing` protocol
 */
- (void)showPreviewForSourceView:(UIView *)sourceView;

@end

