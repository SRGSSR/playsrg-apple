//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SharingItem.h"

#import "ApplicationConfiguration.h"

@interface SharingItem ()

@property (nonatomic) NSURL *URL;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *analyticsUid;

@end

@implementation SharingItem

#pragma mark Class methods

+ (instancetype)sharingItemForMedia:(SRGMedia *)media atTime:(CMTime)time
{
    NSURL *URL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForMediaMetadata:media atTime:time];
    return [[self alloc] initWithURL:URL title:[self titleForMedia:media] analyticsUid:media.URN];
}

+ (instancetype)sharingItemForShow:(SRGShow *)show
{
    NSURL *URL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForShow:show];
    return [[self alloc] initWithURL:URL title:show.title analyticsUid:show.URN];
}

+ (instancetype)sharingItemForContentSection:(SRGContentSection *)contentSection
{
    NSURL *URL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForContentSection:contentSection];
    return [[self alloc] initWithURL:URL title:contentSection.presentation.title analyticsUid:contentSection.uid];
}

+ (NSString *)titleForMedia:(SRGMedia *)media
{
    if (media.show.title && ! [media.title containsString:media.show.title]) {
        return [NSString stringWithFormat:@"%@, %@", media.title, media.show.title];
    }
    else {
        return media.title;
    }
}

#pragma mark Object lifecycle

- (instancetype)initWithURL:(NSURL *)URL title:(NSString *)title analyticsUid:(NSString *)analyticsUid
{
    if (! URL || title.length == 0 || ! analyticsUid) {
        return nil;
    }
    
    if (self = [super init]) {
        self.URL = URL;
        self.title = title;
        self.analyticsUid = analyticsUid;
    }
    return self;
}

#pragma mark UIActivityItemSource protocol

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return self.URL;
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(UIActivityType)activityType
{
    if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard]
            || [activityType isEqualToString:UIActivityTypeAddToReadingList]
            || [activityType isEqualToString:UIActivityTypeAirDrop]
            || [activityType isEqualToString:UIActivityTypeOpenInIBooks]
            || [activityType isEqualToString:UIActivityTypeMail]
            || [activityType isEqualToString:@"com.apple.reminders.RemindersEditorExtension"]) {
        return self.URL;
    }
    else {
        return [NSString stringWithFormat:@"%@ - %@", self.title, self.URL.absoluteString];
    }
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(UIActivityType)activityType
{
    return self.title;
}

@end
