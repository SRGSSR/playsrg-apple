//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SharingItem.h"

#import "ApplicationConfiguration.h"
#import "Banner.h"
#import "PlaySRG-Swift.h"

@interface SharingItem ()

@property (nonatomic) NSURL *URL;
@property (nonatomic, copy) NSString *title;
@property (nonatomic) AnalyticsSharingAction analyticsAction;
@property (nonatomic, copy) NSString *analyticsUid;
@property (nonatomic) AnalyticsSharingMediaContentType mediaContentType;

@end

@implementation SharingItem

AnalyticsSharingSource SharingItemSourceFrom(SharingItemFrom sharingItemFrom) {
    switch (sharingItemFrom) {
        case SharingItemFromButton:
            return AnalyticsSharingSourceButton;
            break;
        case SharingItemFromContextMenu:
            return AnalyticsSharingSourceContextMenu;
            break;
    }
}

#pragma mark Class methods

+ (instancetype)sharingItemForMedia:(SRGMedia *)media atTime:(CMTime)time
{
    NSURL *URL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForMedia:media atTime:time];
    return [[self alloc] initWithURL:URL
                               title:[self titleForMedia:media]
                     analyticsAction:AnalyticsSharingActionMedia
                        analyticsUid:media.URN
                    mediaContentType:CMTIME_COMPARE_INLINE(time, ==, kCMTimeZero) ? AnalyticsSharingMediaContentTypeContent : AnalyticsSharingMediaContentTypeContentAtTime];
}

+ (instancetype)sharingItemForCurrentClip:(SRGMedia *)media
{
    NSURL *URL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForMedia:media atTime:kCMTimeZero];
    return [[self alloc] initWithURL:URL
                               title:[self titleForMedia:media]
                     analyticsAction:AnalyticsSharingActionMedia
                        analyticsUid:media.URN
                    mediaContentType:AnalyticsSharingMediaContentTypeCurrentClip];
}

+ (instancetype)sharingItemForShow:(SRGShow *)show
{
    NSURL *URL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForShow:show];
    return [[self alloc] initWithURL:URL
                               title:show.title
                     analyticsAction:AnalyticsSharingActionShow
                        analyticsUid:show.URN
                    mediaContentType:AnalyticsSharingMediaContentTypeNone];
}

+ (instancetype)sharingItemForContentSection:(SRGContentSection *)contentSection
{
    NSURL *URL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForContentSection:contentSection];
    return [[self alloc] initWithURL:URL
                               title:contentSection.presentation.title
                     analyticsAction:AnalyticsSharingActionSection
                        analyticsUid:contentSection.uid
                    mediaContentType:AnalyticsSharingMediaContentTypeNone];
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

- (instancetype)initWithURL:(NSURL *)URL
                      title:(NSString *)title
            analyticsAction:(AnalyticsSharingAction)analyticsAction
               analyticsUid:(NSString *)analyticsUid
           mediaContentType:(AnalyticsSharingMediaContentType)mediaContentType
{
    if (! URL || title.length == 0 || ! analyticsUid) {
        return nil;
    }
    
    if (self = [super init]) {
        self.URL = URL;
        self.title = title;
        self.analyticsAction = analyticsAction;
        self.analyticsUid = analyticsUid;
        self.mediaContentType = mediaContentType;
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
        // Unbreakable spaces before / after the separator
        return [NSString stringWithFormat:@"%@ - %@", self.title, self.URL.absoluteString];
    }
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(UIActivityType)activityType
{
    return self.title;
}

@end

@implementation UIActivityViewController (SharingItem)

- (instancetype)initWithSharingItem:(SharingItem *)sharingItem
                               from:(SharingItemFrom)sharingItemFrom
                withCompletionBlock:(void (^)(UIActivityType))completionBlock
{
    if (self = [self initWithActivityItems:@[ sharingItem ] applicationActivities:nil]) {
        self.excludedActivityTypes = @[
            UIActivityTypePrint,
            UIActivityTypeAssignToContact,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypePostToFlickr,
            UIActivityTypePostToVimeo,
            UIActivityTypePostToTencentWeibo,
            UIActivityTypePostToWeibo,
            UIActivityTypeOpenInIBooks,
            UIActivityTypeMarkupAsPDF
        ];
        self.completionWithItemsHandler = ^(UIActivityType __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError) {
            if (! completed || ! activityType) {
                return;
            }
            
            [[AnalyticsHiddenEventObjC sharingWithAction:sharingItem.analyticsAction
                                                     uid:sharingItem.analyticsUid
                                        mediaContentType:sharingItem.mediaContentType
                                                  source:SharingItemSourceFrom(sharingItemFrom)
                                                    type:activityType] send];
            
            if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard]) {
                [Banner showWithStyle:BannerStyleInfo
                              message:NSLocalizedString(@"The content has been copied to the clipboard.", @"Message displayed when some content (media, show, etc.) has been copied to the clipboard")
                                image:nil
                               sticky:NO];
            }
            
            completionBlock ? completionBlock(activityType) : nil;
        };
    }
    return self;
}

@end
