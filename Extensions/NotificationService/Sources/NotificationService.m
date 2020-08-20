//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NotificationService.h"

#import "Notification.h"

@import MobileCoreServices;

static NSString *NotificationServiceUTIFromMIMEType(NSString *MIMEType)
{
    return (__bridge NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)MIMEType, NULL);
}

@interface NotificationService ()

@property (nonatomic, copy) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic) UNNotificationContent *notificationContent;

@property (nonatomic) NSURLSessionDownloadTask *downloadTask;

@end

@implementation NotificationService

#pragma mark Subclassing hooks

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler
{
    UNNotificationContent *notificationContent = request.content;
    
    // Keep references for expiration method implementation
    self.notificationContent = notificationContent;
    self.contentHandler = contentHandler;
    
    Notification *notification = [[Notification alloc] initWithRequest:request];
    [Notification saveNotification:notification read:NO];
    
    if (notification.imageURL) {
        self.downloadTask = [self imageDownloadTaskForNotification:notification withCompletion:^(UNNotificationAttachment * _Nullable attachment) {
            if (attachment) {
                UNMutableNotificationContent *mutableNotificationContent = notificationContent.mutableCopy;
                mutableNotificationContent.attachments = @[attachment];
                contentHandler(mutableNotificationContent.copy);
            }
            else {
                contentHandler(notificationContent);
            }
        }];
        [self.downloadTask resume];
    }
    else {
        contentHandler(notificationContent);
    }
}

- (void)serviceExtensionTimeWillExpire
{
    [self.downloadTask cancel];
    self.contentHandler(self.notificationContent);
}

#pragma mark UNNotificationAttachment for image

- (NSURLSessionDownloadTask *)imageDownloadTaskForNotification:(Notification *)notification withCompletion:(void (^)(UNNotificationAttachment * _Nullable attachment))completion
{
    NSParameterAssert(completion);
    
    static CGFloat s_imageWidth;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        CGFloat imageWidth;
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            imageWidth = 340.f;
        }
        else {
            imageWidth = 500.f;
        }
        
        // Use 2x maximum as scale. Sufficient for a good result without having to load very large images
        s_imageWidth = imageWidth * fminf(UIScreen.mainScreen.scale, 2.f);
    });
    
    NSURL *scaledImageURL = [notification imageURLForDimension:SRGImageDimensionWidth withValue:s_imageWidth type:SRGImageTypeDefault];
    return [[NSURLSession sharedSession] downloadTaskWithURL:scaledImageURL completionHandler:^(NSURL *temporaryFileURL, NSURLResponse *response, NSError *error) {
        if (error) {
            completion(nil);
            return;
        }
        
        NSString *MIMEType = response.MIMEType;
        if (! MIMEType) {
            completion(nil);
            return;
        }
        
        NSString *UTI = NotificationServiceUTIFromMIMEType(MIMEType);
        if (! UTI) {
            completion(nil);
            return;
        }
        
        NSDictionary *options = @{ UNNotificationAttachmentOptionsTypeHintKey : UTI };
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:temporaryFileURL options:options error:NULL];
        completion(attachment);
    }];
}

@end
