//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

#import <CoconutKit/CoconutKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Abstract common base view controller class for view controllers in the Play application. This class provides:
 *  standard content preview and context menu management (long-press / 3D touch).
 */
@interface BaseViewController : HLSViewController <PreviewingDelegate, UIContextMenuInteractionDelegate>

@end

NS_ASSUME_NONNULL_END
