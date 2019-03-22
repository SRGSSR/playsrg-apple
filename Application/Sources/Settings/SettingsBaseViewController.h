//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"

#import "InAppSettingsKit/IASKAppSettingsViewController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Common generic class for settings view controllers for display with InAppSettingsKit. Provide standard
 *  SRG-compliant design and consistent behavior
 */
@interface SettingsBaseViewController : IASKAppSettingsViewController <ContentInsets, IASKSettingsDelegate>

@end

NS_ASSUME_NONNULL_END
