//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ActivityItemSource.h"

@protocol ActivityItemSource <NSObject>

@property (nonatomic, readonly) NSString *subject;

@end

@interface SRGMedia (ActivityItemSource) <ActivityItemSource>

@end

@interface SRGShow (ActivityItemSource) <ActivityItemSource>

@end

@interface ActivityItemSource ()

@property (nonatomic) id<ActivityItemSource> source;
@property (nonatomic) NSURL *URL;

@end

@implementation ActivityItemSource

#pragma mark Object lifecycle

- (instancetype)initWithMedia:(SRGMedia *)media URL:(NSURL *)URL
{
    if (self = [super init]) {
        self.source = media;
        self.URL = URL;
    }
    return self;
}

- (instancetype)initWithShow:(SRGShow *)show URL:(NSURL *)URL
{
    if (self = [super init]) {
        self.source = show;
        self.URL = URL;
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
        return [NSString stringWithFormat:@"%@ - %@", self.source.subject, self.URL.absoluteString];
    }
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(nullable UIActivityType)activityType
{
    return self.source.subject;
}

@end

@implementation SRGMedia (ActivityItemSource)

- (NSString *)subject
{
    if (self.show.title && ! [self.title containsString:self.show.title]) {
        return [NSString stringWithFormat:@"%@, %@", self.title, self.show.title];
    }
    else {
        return self.title;
    }
}

@end

@implementation SRGShow (ActivityItemSource)

- (NSString *)subject
{
    return self.title;
}

@end
