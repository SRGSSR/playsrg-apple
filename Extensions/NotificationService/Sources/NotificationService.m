//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NotificationService.h"

#import "UserNotification.h"

@import MobileCoreServices;
@import SRGDataProviderNetwork;

static NSString *NotificationServiceUTIFromMIMEType(NSString *MIMEType)
{
    return (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)MIMEType, NULL));
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
    
    UserNotification *notification = [[UserNotification alloc] initWithRequest:request];
    [UserNotification saveNotification:notification read:NO];
    
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

- (NSURLSessionDownloadTask *)imageDownloadTaskForNotification:(UserNotification *)notification withCompletion:(void (^)(UNNotificationAttachment * _Nullable attachment))completion
{
    NSParameterAssert(completion);
    
    static SRGDataProvider *s_dataProvider;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    });
    
    SRGImage *image = [SRGImage imageWithURL:notification.imageURL variant:SRGImageVariantDefault];
    NSURL *scaledImageURL = [s_dataProvider URLForImage:image withSize:SRGImageSizeMedium scaling:SRGImageScalingDefault];
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
