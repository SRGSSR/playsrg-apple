//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NotificationService.h"

#import "Notification.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface NotificationService ()

@property (nonatomic, copy) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic) UNMutableNotificationContent *originalNotificationContent;

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@end

@implementation NotificationService

#pragma mark Subclassing hooks

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler
{
    self.contentHandler = contentHandler;
    self.originalNotificationContent = [request.content mutableCopy];
    
    Notification *notification = [[Notification alloc] initWithRequest:request];
    [Notification saveNotification:notification read:NO];
    
    if (notification.imageURL) {
        self.downloadTask = [self imageDownloadTaskForNotification:notification];
        [self.downloadTask resume];
    } else {
        self.contentHandler(self.originalNotificationContent);
    }
}

- (void)serviceExtensionTimeWillExpire
{
    [self.downloadTask cancel];
    self.contentHandler(self.originalNotificationContent);
}

#pragma mark UNNotificationAttachment for image

// Inspired by UAMediaAttachmentExtension from AirShip

- (NSURLSessionDownloadTask *)imageDownloadTaskForNotification:(Notification *)notification
{
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
    
    return [[NSURLSession sharedSession] downloadTaskWithURL:scaledImageURL completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
                if (error) {
                    self.contentHandler(self.originalNotificationContent);
                    return;
                }
                
                NSString *mimeType = nil;
                if ([response isKindOfClass:NSHTTPURLResponse.class]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    mimeType = httpResponse.allHeaderFields[@"Content-Type"];
                }
        
                UNNotificationAttachment *attachment = [self attachmentWithTemporaryFileLocation:temporaryFileLocation
                                                                                     originalURL:notification.imageURL
                                                                                        mimeType:mimeType
                                                                                         options:nil];
        
                // A nil attachment may indicate an unrecognized file type
                if (! attachment) {
                    self.contentHandler(self.originalNotificationContent);
                    return;
                }
                
                self.originalNotificationContent.attachments = @[attachment];
                
                self.contentHandler(self.originalNotificationContent);
            }];
}

- (UNNotificationAttachment *)attachmentWithTemporaryFileLocation:(NSURL *)location
                                                      originalURL:(NSURL *)originalURL
                                                         mimeType:(NSString *)mimeType
                                                          options:(NSDictionary *)options
{
    NSURL *fileURL = [self processTempFile:location originalURL:originalURL];
    
    if (! fileURL) {
        return nil;
    }
    
    NSArray *knownExtensions = @[@"jpg", @"jpeg", @"png", @"gif", @"aif", @"aiff", @"mp3",
                                 @"mpg", @"mpeg", @"mp4", @"m4a", @"wav", @"avi"];
    BOOL hasExtension = NO;
    for (NSString *extension in knownExtensions) {
        if ([[fileURL.lastPathComponent lowercaseString] hasSuffix:extension]) {
            hasExtension = YES;
        }
    }
    
    // No extension, try to determine the type
    if (! hasExtension) {
        NSString *inferredTypeIdentifier = nil;
        
        // First try the mimetype if its available
        if (mimeType) {
            CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimeType, NULL);
            
            CFStringRef acceptedTypes[] = { kUTTypeAudioInterchangeFileFormat, kUTTypeWaveformAudio,
                kUTTypeMP3, kUTTypeMPEG4Audio, kUTTypeJPEG, kUTTypeGIF, kUTTypePNG, kUTTypeMPEG,
                kUTTypeMPEG2Video, kUTTypeMPEG4, kUTTypeAVIMovie };
            
            
            for (int i = 0; i < 11; i++) {
                if (UTTypeConformsTo(uti, acceptedTypes[i])) {
                    inferredTypeIdentifier = (__bridge_transfer NSString *)uti;
                    break;
                }
            }
        }
        
        // Fallback to file header inspection
        if (! inferredTypeIdentifier.length) {
            // Note: NSMappedRead will page in the data as it's read, so we don't load the whole file into memory
            NSData *fileData = [NSData dataWithContentsOfFile:fileURL.path
                                                      options:NSMappedRead
                                                        error:nil];
            inferredTypeIdentifier = [self uniformTypeIdentifierForData:fileData];
        }
        
        if (inferredTypeIdentifier) {
            options = [NSMutableDictionary dictionaryWithDictionary:options];
            [options setValue:inferredTypeIdentifier forKey:UNNotificationAttachmentOptionsTypeHintKey];
        }
    }
    
    NSError *error;
    UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:originalURL.description URL:fileURL options:options error:&error];
    
    return attachment;
}

- (NSURL *)processTempFile:(NSURL *)tempFileURL originalURL:originalURL
{
    // Affix the original filename, as the temp file will be lacking a file type
    NSString *suffix = [NSString stringWithFormat:@"-%@", [originalURL lastPathComponent]];
    NSURL *destinationURL = [NSURL fileURLWithPath:[tempFileURL.path stringByAppendingString:suffix]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Remove anything currently existing at the destination path
    if ([fm fileExistsAtPath:destinationURL.path]) {
        NSError *error;
        [fm removeItemAtPath:destinationURL.path error:&error];
    }
    
    // Rename temp file
    NSError *error;
    [fm moveItemAtURL:tempFileURL toURL:destinationURL error:&error];
    
    return destinationURL;
}

- (NSString *)uniformTypeIdentifierForData:(NSData *)data
{
    // Grab the first 16 bytes
    NSUInteger length = 16;
    
    if (data.length < length) {
        return nil;
    }
    
    uint8_t header[length];
    [data getBytes:&header length:length];
    
    // Compare against known type signatures
    NSDictionary *types = [self uniformTypeIdentifierMap];
    
    for (NSString *typeIdentifier in types) {
        NSArray *signatures = types[typeIdentifier];
        for (NSDictionary *signature in signatures) {
            NSUInteger offset = [signature[@"offset"] unsignedIntegerValue];
            NSUInteger signatureLength = [signature[@"length"] unsignedIntegerValue];
            NSData *bytes = signature[@"bytes"];
            
            if (memcmp(header + offset, bytes.bytes, signatureLength) == 0) {
                return typeIdentifier;
            }
        }
    }
    
    return nil;
}

- (NSDictionary *)uniformTypeIdentifierMap
{
    // Offset 0
    uint8_t jpeg[] = {0xFF, 0xD8, 0xFF, 0xE0};
    uint8_t jpegAlt[] = {0xFF, 0xD8, 0xFF, 0xE2};
    uint8_t jpegAlt2[] = {0xFF, 0xD8, 0xFF, 0xE3};
    uint8_t png[] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
    uint8_t gif[] = {0x47, 0x49, 0x46, 0x38};
    uint8_t aiff[] = {0x46, 0x4F, 0x52, 0x4D, 0x00};
    uint8_t mp3[] = {0x49, 0x44, 0x33};
    uint8_t mpeg[] = {0x00, 0x00, 0x01, 0xBA};
    uint8_t mpegAlt[] = {0x00, 0x00, 0x01, 0xB3};
    
    // Offset 4
    uint8_t mp4v1[] = {0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x31};
    uint8_t mp4v2[] = {0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32};
    uint8_t mp4mmp4[] = {0x66, 0x74, 0x79, 0x70, 0x6D, 0x6D, 0x70, 0x34};
    uint8_t mp4isom[] = {0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6f, 0x6d};
    uint8_t m4a[] = {0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41, 0x20};
    
    // Offset 8
    uint8_t wav[] = {0x57, 0x41, 0x56, 0x45};
    uint8_t avi[] = {0x41, 0x56, 0x49, 0x20};
    
    // Convenience block for building signature info
    NSDictionary * (^sig)(NSUInteger, uint8_t *, NSUInteger) = ^NSDictionary *(NSUInteger offset, uint8_t *bytes, NSUInteger length) {
        NSData *data = [NSData dataWithBytes:bytes length:length];
        return @{@"offset" : @(offset), @"length": @(length), @"bytes":data};
    };
    
    // Known type identifiers and their respective signatures
    NSDictionary *types = @{@"public.jpeg" : @[sig(0, jpeg, sizeof(jpeg)), sig(0, jpegAlt, sizeof(jpegAlt)), sig(0, jpegAlt2, sizeof(jpegAlt2))],
                            @"public.png" : @[sig(0, png, sizeof(png))],
                            @"com.compuserve.gif" : @[sig(0, gif, sizeof(gif))],
                            @"public.aiff-audio" : @[sig(0, aiff, sizeof(aiff))],
                            @"com.microsoft.waveform-audio" : @[sig(8, wav, sizeof(wav))],
                            @"public.avi" : @[sig(8, avi, sizeof(avi))],
                            @"public.mp3" : @[sig(0, mp3, sizeof(mp3))],
                            @"public.mpeg-4" : @[sig(4, mp4v1, sizeof(mp4v1)), sig(4, mp4v2, sizeof(mp4v2)), sig(4, mp4mmp4, sizeof(mp4mmp4)), sig(4, mp4isom, sizeof(mp4isom))],
                            @"public.mpeg-4-audio" : @[sig(4, m4a, sizeof(m4a))],
                            @"public.mpeg" : @[sig(0, mpeg, sizeof(mpeg)), sig(0, mpegAlt, sizeof(mpegAlt))]};
    
    return types;
}

@end
