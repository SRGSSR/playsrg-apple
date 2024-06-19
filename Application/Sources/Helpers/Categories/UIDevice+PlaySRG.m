//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIDevice+PlaySRG.h"

#import "PlaySRG-Swift.h"

@import libextobjc;

static BOOL s_locked = NO;

// Function declarations
static void lockComplete(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
static UIInterfaceOrientationMask MediaPlayerUserInterfaceOrientationMask(UIInterfaceOrientation orientation);

@implementation UIDevice (PlaySRG)

#pragma mark Class methods

+ (BOOL)play_isLocked
{
    return s_locked;
}

#pragma mark Rotation

- (void)rotateToUserInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (@available(iOS 16, *)) {
        UIInterfaceOrientationMask interfaceOrientationMask = MediaPlayerUserInterfaceOrientationMask(orientation);
        UIWindowSceneGeometryPreferences *preferences = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:interfaceOrientationMask];
        [UIApplication.sharedApplication.mainWindowScene requestGeometryUpdateWithPreferences:preferences errorHandler:nil];
    }
    else {
        // User interface orientations are a subset of device orientations with matching values. Trick: To avoid the
        // system inhibiting some rotation attempts for which it would detect no meaningful change, we perform a
        // change to portrait mode first).
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            [UIDevice.currentDevice setValue:@(UIInterfaceOrientationPortrait) forKey:@keypath(UIDevice.new, orientation)];
        }
        [UIDevice.currentDevice setValue:@(orientation) forKey:@keypath(UIDevice.new, orientation)];
    }
}

#pragma mark Notifications

+ (void)play_applicationDidBecomeActive:(NSNotification *)notification
{
    s_locked = NO;
}

@end

#pragma mark Functions

__attribute__((constructor)) static void PlayUIDeviceInit(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Differentiate between device lock and application sent to the background
        // See http://stackoverflow.com/a/9058038/760435
        NSString *notification = [[[NSString stringWithFormat:@"122c1o6m7.a8p93p0l99e8.s65p4r43i32ng2b1234o2a432rd.l23o3c25567k8c9o08m65p43l32e2te"] componentsSeparatedByCharactersInSet:NSCharacterSet.decimalDigitCharacterSet] componentsJoinedByString:@""];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        (__bridge const void *)UIDevice.class,
                                        lockComplete,
                                        (__bridge CFStringRef)notification,
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        
        [NSNotificationCenter.defaultCenter addObserver:UIDevice.class
                                               selector:@selector(play_applicationDidBecomeActive:)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
    });
}

static void lockComplete(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    s_locked = YES;
}

static UIInterfaceOrientationMask MediaPlayerUserInterfaceOrientationMask(UIInterfaceOrientation orientation)
{
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft: {
            return UIInterfaceOrientationMaskLandscapeLeft;
            break;
        }
            
        case UIInterfaceOrientationLandscapeRight: {
            return UIInterfaceOrientationMaskLandscapeRight;
            break;
        }
            
        case UIInterfaceOrientationPortraitUpsideDown: {
            return UIInterfaceOrientationMaskPortraitUpsideDown;
            break;
        }
            
        default: {
            return UIInterfaceOrientationMaskPortrait;
            break;
        }
    }
}
