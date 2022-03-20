//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Banner.h"

#import "NSBundle+PlaySRG.h"
#import "PlaySRG-Swift.h"
#import "UIColor+PlaySRG.h"
#import "UIView+PlaySRG.h"

@import SRGAppearance;
@import SRGDataProvider;

static NSString *BannerShortenedName(NSString *name);

@implementation Banner

#pragma mark Class methods

+ (void)showWithStyle:(BannerStyle)style message:(NSString *)message image:(UIImage *)image sticky:(BOOL)sticky
{
    if (! message) {
        return;
    }
    
    NSString *accessibilityPrefix = nil;
    UIColor *backgroundColor = nil;
    UIColor *foregroundColor = nil;
    
    switch (style) {
        case BannerStyleInfo: {
            accessibilityPrefix = PlaySRGAccessibilityLocalizedString(@"Information", @"Introductory title for information notifications");
            backgroundColor = [UIColor srg_blueColor];
            foregroundColor = UIColor.whiteColor;
            break;
        }
            
        case BannerStyleWarning: {
            accessibilityPrefix = PlaySRGAccessibilityLocalizedString(@"Warning", @"Introductory title for warning notifications");
            backgroundColor = UIColor.orangeColor;
            foregroundColor = UIColor.blackColor;
            break;
        }
            
        case BannerStyleError: {
            accessibilityPrefix = PlaySRGAccessibilityLocalizedString(@"Error", @"Introductory title for error notifications");
            backgroundColor = UIColor.srg_redColor;
            foregroundColor = UIColor.whiteColor;
            break;
        }
    }
    
    [SwiftMessagesBridge show:message accessibilityPrefix:accessibilityPrefix image:image backgroundColor:backgroundColor foregroundColor:foregroundColor sticky:sticky];
}

+ (void)hideAll
{
    [SwiftMessagesBridge hideAll];
}

@end

@implementation Banner (Convenience)

+ (void)showError:(NSError *)error
{
    if (! error) {
        return;
    }
    
    // Multiple errors. Pick the first ones
    if ([error.domain isEqualToString:SRGNetworkErrorDomain] && error.code == SRGNetworkErrorMultiple) {
        error = [error.userInfo[SRGNetworkErrorsKey] firstObject];
    }
    
    // Never display cancellation errors
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        return;
    }
    
    [self showWithStyle:BannerStyleError message:error.localizedDescription image:nil sticky:NO];
}

+ (void)showFavorite:(BOOL)isFavorite forItemWithName:(NSString *)name
{
    if (! name) {
        name = NSLocalizedString(@"The selected content", @"Name of the favorite item, if no title or name to display");
    }
    
    NSString *messageFormatString = isFavorite ? NSLocalizedString(@"%@ has been added to favorites", @"Message displayed at the top of the screen when adding a show to favorites. Quotes are managed by the application.") : NSLocalizedString(@"%@ has been deleted from favorites", @"Message displayed at the top of the screen when removing a show from favorites. Quotes are managed by the application.");
    NSString *message = [NSString stringWithFormat:messageFormatString, BannerShortenedName(name)];
    UIImage *image = isFavorite ? [UIImage imageNamed:@"favorite_full"] : [UIImage imageNamed:@"favorite"];
    [self showWithStyle:BannerStyleInfo message:message image:image sticky:NO];
}

+ (void)showDownload:(BOOL)downloaded forItemWithName:(NSString *)name
{
    if (! name) {
        name = NSLocalizedString(@"The selected content", @"Name of the download item, if no title or name to display");
    }
    
    NSString *messageFormatString = downloaded ? NSLocalizedString(@"%@ has been added to downloads", @"Message displayed at the top of the screen when adding a media to downloads. Quotes are managed by the application.") : NSLocalizedString(@"%@ has been deleted from downloads", @"Message displayed at the top of the screen when removing a media from downloads. Quotes are managed by the application.");
    NSString *message = [NSString stringWithFormat:messageFormatString, BannerShortenedName(name)];
    UIImage *image = downloaded ? [UIImage imageNamed:@"download"] : [UIImage imageNamed:@"download_remove"];
    [self showWithStyle:BannerStyleInfo message:message image:image sticky:NO];
}

+ (void)showSubscription:(BOOL)subscribed forItemWithName:(NSString *)name
{
    if (! name) {
        name = NSLocalizedString(@"The selected content", @"Name of the subscription item, if no title or name to display");
    }
    
    NSString *messageFormatString = subscribed ? NSLocalizedString(@"Notifications have been enabled for %@", @"Message displayed at the top of the screen when enabling push notifications. Quotes around the content placeholder managed by the application.") : NSLocalizedString(@"Notifications have been disabled for %@", @"Message at the top of the screen displayed when disabling push notifications. Quotes around the content placeholder are managed by the application.");
    NSString *message = [NSString stringWithFormat:messageFormatString, BannerShortenedName(name)];
    UIImage *image = subscribed ? [UIImage imageNamed:@"subscription_full"] : [UIImage imageNamed:@"subscription"];
    [self showWithStyle:BannerStyleInfo message:message image:image sticky:NO];
}

+ (void)showWatchLaterAdded:(BOOL)added forItemWithName:(NSString *)name
{
    if (! name) {
        name = NSLocalizedString(@"The selected content", @"Name of the later list item, if no title or name to display");
    }
    
    NSString *messageFormatString = added ? NSLocalizedString(@"%@ has been added to \"Later\"", @"Message displayed at the top of the screen when adding a media to the later list. Quotes around the content placeholder are managed by the application.") : NSLocalizedString(@"%@ has been deleted from \"Later\"", @"Message displayed at the top of the screen when removing an item from the later list. Quotes around the content placeholder are managed by the application.");
    NSString *message = [NSString stringWithFormat:messageFormatString, BannerShortenedName(name)];
    UIImage *image = added ? [UIImage imageNamed:@"watch_later_full"] : [UIImage imageNamed:@"watch_later"];
    [self showWithStyle:BannerStyleInfo message:message image:image sticky:NO];
}

@end

static NSString *BannerShortenedName(NSString *name)
{
    if (name) {
        static const NSUInteger kMaxTitleLength = 60;
        
        if (name.length > kMaxTitleLength) {
            name = [[name substringWithRange:NSMakeRange(0, kMaxTitleLength)] stringByAppendingString:@"…"];
        }
        return [NSString stringWithFormat:@"\"%@\"", name];
    }
    else {
        return nil;
    }
}
