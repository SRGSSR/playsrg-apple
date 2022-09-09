//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Download.h"

#import "DownloadSession.h"
#import "NSDateFormatter+PlaySRG.h"
#import "PlaySRG-Swift.h"
#import "PlayErrors.h"
#import "PlayLogger.h"
#import "UIImage+PlaySRG.h"

@import FXReachability;
@import libextobjc;
@import SRGDataProviderNetwork;

NSString * const DownloadStateDidChangeNotification = @"DownloadStateDidChangeNotification";
NSString * const DownloadStateKey = @"DownloadState";

static NSMutableDictionary<NSString *, Download *> *s_downloadsDictionary;
static NSArray<Download *> *s_sortedDownloads;

@interface Download ()

@property (nonatomic) SRGMedia *media;
@property (nonatomic) NSDate *creationDate;
@property (nonatomic) DownloadState state;

@property (nonatomic, nullable) NSURL *downloadImageURL;

@property (nonatomic) NSString *localMediaFileName;
@property (nonatomic) NSString *localImageFileName;

@property (nonatomic) SRGPresentation presentation;

// SRGMediaMetadata Protocol

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *URN;
@property (nonatomic) SRGMediaType mediaType;
@property (nonatomic) SRGVendor vendor;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *lead;
@property (nonatomic, copy) NSString *summary;

@property (nonatomic, copy) NSString *imageTitle;
@property (nonatomic, copy) NSString *imageCopyright;

@property (nonatomic) SRGContentType contentType;
@property (nonatomic) SRGSource source;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) SRGBlockingReason blockingReason;     // Only for backup. Use as originalBlockingReason;
@property (nonatomic) SRGYouthProtectionColor youthProtectionColor;
@property (nonatomic) NSURL *podcastStandardDefinitionURL;
@property (nonatomic) NSURL *podcastHighDefinitionURL;
@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *endDate;
@property (nonatomic) NSString *accessibilityTitle;
// Don't save relatedContents
// Don't save socialCounts

@property (nonatomic, readonly) NSDictionary *backupDictionary;

@end

@implementation Download

#pragma mark Class methods

/**
 *  Downloads are saved with AutoCoding in the "downloadsFilePath" file
 *  A corrupted file, or an update of the model object, or the related object model linked to it, can broke the download restoration.
 *  In the case, the initializer try to load the "downloadsBackupFilePath" file.
 *  The "downloadsBackupFilePath" file is a simple plsit file without the related object.
 *  It creates a light download object, with just information to display it and play offline file.
 */

+ (void)initialize
{
    if (self != Download.class) {
        return;
    }
    
    @try {
        s_downloadsDictionary = [self loadDownloadsDictionary];
    }
    @catch (NSException *exception) {
        PlayLogWarning(@"download", @"Download migration failed. Use backup dictionary instead");
    }
    
    // If model objects changed, or the plist file is corrupted,
    // We try to load lazy downloads from the backup file.
    if (s_downloadsDictionary.count == 0) {
        NSDictionary *backupDownload = [self loadDownloadsBackupDictionary];
        if (backupDownload.count > 0) {
            s_downloadsDictionary = backupDownload.mutableCopy;
            [self saveDownloadsDictionary];
        }
    }
    
    // If no backups, start an empty download list
    if (! s_downloadsDictionary) {
        s_downloadsDictionary = [NSMutableDictionary dictionary];
    }
    
    // Start downloads
    [s_downloadsDictionary.allValues enumerateObjectsUsingBlock:^(Download * _Nonnull download, NSUInteger idx, BOOL * _Nonnull stop) {
        [download setNeedsStateUpdateSilent:YES];
        [DownloadSession.sharedDownloadSession addDownload:download];
    }];
}

+ (NSString *)downloadsFilePath
{
    NSString *libraryDirectoryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return [libraryDirectoryPath stringByAppendingPathComponent:@"downloads.plist"];
}

+ (NSMutableDictionary<NSString *, Download *> *)loadDownloadsDictionary
{
    NSString *downloadsFilePath = [self downloadsFilePath];
    if (! [NSFileManager.defaultManager fileExistsAtPath:downloadsFilePath]) {
        return nil;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:downloadsFilePath];
    NSError *error = nil;
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
    unarchiver.requiresSecureCoding = NO;
    
    NSMutableDictionary<NSString *, Download *> *downloadsDictionary = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    if (! downloadsDictionary) {
        PlayLogError(@"download", @"Could not load download dictionary. Reason: %@", error);
        return nil;
    }
    
    NSPredicate *isNotNSString = [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:NSString.class];
    }];
    if ([downloadsDictionary.allKeys filteredArrayUsingPredicate:isNotNSString].count != 0) {
        return nil;
    }
    
    NSPredicate *isNotDownload = [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:Download.class];
    }];
    if ([downloadsDictionary.allValues filteredArrayUsingPredicate:isNotDownload].count != 0) {
        return nil;
    }
    
    return downloadsDictionary;
}

+ (void)saveDownloadsDictionary
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:s_downloadsDictionary requiringSecureCoding:NO error:NULL];
    [data writeToFile:[self downloadsFilePath] atomically:YES];
    
    [self saveDownloadsBackupDictionary];
}

+ (NSString *)downloadsBackupFilePath
{
    NSString *libraryDirectoryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return [libraryDirectoryPath stringByAppendingPathComponent:@"downloadsBackup.plist"];
}

+ (NSDictionary<NSString *, Download *> *)loadDownloadsBackupDictionary
{
    NSMutableDictionary *downloadsBackupDictionary = [NSMutableDictionary dictionary];
    NSDictionary *backupFileDictionnary = [NSDictionary dictionaryWithContentsOfFile:[self downloadsBackupFilePath]];
    [backupFileDictionnary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            NSDictionary *downloadDictionary = (NSDictionary *)obj;
            Download *download = [[Download alloc] initWithDictionary:downloadDictionary];
            if (download && [key isEqualToString:download.URN]) {
                // Set the key as an SRGMediaURN
                downloadsBackupDictionary[download.URN] = download;
            }
            else {
                PlayLogError(@"download", @"Could not open download for key %@. Skipped", key);
            }
        }
    }];
    
    return downloadsBackupDictionary.copy;
}

+ (void)saveDownloadsBackupDictionary
{
    // Backup file has only basic Objective-C objects
    NSMutableDictionary *downloadsBackupDictionary = [NSMutableDictionary dictionary];
    [s_downloadsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull URN, Download * _Nonnull download, BOOL * _Nonnull stop) {
        downloadsBackupDictionary[URN] = download.backupDictionary;
    }];
    
    NSError *plistError = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:downloadsBackupDictionary
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:&plistError];
    if (plistError) {
        PlayLogError(@"download", @"Could not save downloads data. Reason: %@", plistError);
        NSAssert(NO, @"Could not save downloads backup data. Not safe. See error above.");
        return;
    }
    
    NSError *writeError = nil;
    [plistData writeToFile:[self downloadsBackupFilePath] options:NSDataWritingAtomic error:&writeError];
    if (writeError) {
        PlayLogError(@"download", @"Could not save downloads data. Reason: %@", writeError);
        NSAssert(NO, @"Could not save downloads backup data. Not safe. See error above.");
    }
}

+ (BOOL)addDownload:(Download *)download
{
    Download *existingDownload = s_downloadsDictionary[download.URN];
    if (existingDownload) {
        return NO;
    }
    
    s_downloadsDictionary[download.URN] = download;
    s_sortedDownloads = nil;            // Invalidate sorted download cache
    
    [self saveDownloadsDictionary];
    
    [DownloadSession.sharedDownloadSession addDownload:download];
    
    return YES;
}

+ (NSString *)downloadsDirectoryURLString
{
    static NSString *s_downloadsDirectoryURLString;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        NSString *libraryDirectoryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
        s_downloadsDirectoryURLString = [libraryDirectoryPath stringByAppendingPathComponent:@"Downloads"];
        NSError *error = nil;
        [NSFileManager.defaultManager createDirectoryAtPath:s_downloadsDirectoryURLString
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&error];
    });
    return s_downloadsDirectoryURLString;
}

+ (void)removeUnusedDownloadedFiles
{
    NSArray *downloadedMediaFilesURLs = [Download.downloads valueForKey:@keypath(Download.new, localMediaFileURL)];
    NSArray *downloadedImageFilesURLs = [Download.downloads valueForKey:@keypath(Download.new, localImageFileURL)];
    NSArray *allDownloadedFilesURLs = [[@[] arrayByAddingObjectsFromArray:downloadedMediaFilesURLs] arrayByAddingObjectsFromArray:downloadedImageFilesURLs];
    NSString *folderPath = [self downloadsDirectoryURLString];
    NSError *error;
    for (NSString *fileName in [NSFileManager.defaultManager contentsOfDirectoryAtPath:folderPath error:&error]) {
        NSURL *fileURL = [NSURL fileURLWithPath:[folderPath stringByAppendingPathComponent:fileName]];
        if (! [allDownloadedFilesURLs containsObject:fileURL]) {
            [NSFileManager.defaultManager removeItemAtURL:fileURL error:&error];
        }
    }
}

+ (void)updateUnplayableDownloads
{
    NSMutableArray<Download *> *unplayableDownloadeds = NSMutableArray.array;
    for (Download *download in Download.downloads) {
        if (download.state == DownloadStateDownloaded && [download.localMediaFileName.pathExtension isEqualToString:@"octet-stream"]) {
            // Try to move media file with the download url extension
            if (download.downloadMediaURL.pathExtension) {
                NSURL *sourceURL = download.localMediaFileURL;
                
                NSString *localMediaFileName = [download.localMediaFileName stringByReplacingOccurrencesOfString:download.localMediaFileName.pathExtension
                                                                                                      withString:download.downloadMediaURL.pathExtension];
                NSString *mediaFilePath = [[Download downloadsDirectoryURLString] stringByAppendingPathComponent:localMediaFileName];
                NSURL *destinationURL = [NSURL fileURLWithPath:mediaFilePath];
                [NSFileManager.defaultManager moveItemAtURL:sourceURL toURL:destinationURL error:nil];
                
                download.localMediaFileName = localMediaFileName;
                if (! download.localMediaFileURL) {
                    [unplayableDownloadeds addObject:download];
                }
            }
            else {
                [unplayableDownloadeds addObject:download];
            }
        }
    }
    [Download removeDownloads:unplayableDownloadeds.copy];
    [self saveDownloadsDictionary];
}

#pragma mark Public class methods

+ (NSArray<Download *> *)downloads
{
    if (! s_sortedDownloads) {
        NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(Download.new, creationDate) ascending:NO];
        s_sortedDownloads = [s_downloadsDictionary.allValues sortedArrayUsingDescriptors:@[dateSortDescriptor]];
    }
    return s_sortedDownloads;
}

+ (BOOL)canDownloadMedia:(SRGMedia *)media
{
    return media.podcastHighDefinitionURL || media.podcastStandardDefinitionURL;
}

+ (BOOL)canToggleDownloadForMedia:(SRGMedia *)media
{
    return [Download canDownloadMedia:media] || [self downloadForMedia:media];
}

+ (Download *)addDownloadForMedia:(SRGMedia *)media
{
    if ([Download canDownloadMedia:media]) {
        Download *download = [self downloadForMedia:media];
        if (! download) {
            download = [[Download alloc] initWithMedia:media];
            s_downloadsDictionary[media.URN] = download;
            s_sortedDownloads = nil;            // Invalidate sorted download cache
            [self saveDownloadsDictionary];
            
            download.state = DownloadStateAdded;
            
            [UserInteractionEvent addToDownloads:@[download]];
        }
        
        if ([DownloadSession.sharedDownloadSession addDownload:download]) {
            [download setNeedsStateUpdate];
        }
        
        return download;
    }
    else {
        return nil;
    }
}

+ (void)removeDownloads:(NSArray<Download *> *)downloads
{
    NSMutableArray<Download *> *removedDownloads = [NSMutableArray array];
    for (Download *download in downloads) {
        if (! download.URN || !s_downloadsDictionary[download.URN]) {
            continue;
        }
        
        [s_downloadsDictionary removeObjectForKey:download.URN];
        [DownloadSession.sharedDownloadSession removeDownload:download];
        [download removeLocalFiles];
        
        download.state = DownloadStateRemoved;
        [removedDownloads addObject:download];
    }
    
    s_sortedDownloads = nil;            // Invalidate sorted download cache
    [self saveDownloadsDictionary];
    
    [UserInteractionEvent removeFromDownloads:removedDownloads.copy];
}

+ (Download *)downloadForMedia:(SRGMedia *)media
{
    Download *download = s_downloadsDictionary[media.URN];
    
    // Update download with the object
    if (download && (! download.media || ! [media isEqual:download.media])) {
        [download updateWithMedia:media];
        [self saveDownloadsDictionary];
    }
    
    return download;
}

+ (Download *)downloadForURN:(NSString *)URN
{
    return s_downloadsDictionary[URN];
}

+ (void)removeAllDownloads
{
    NSArray <Download *> *downloads = s_downloadsDictionary.allValues;
    
    [s_downloadsDictionary removeAllObjects];
    
    [downloads enumerateObjectsUsingBlock:^(Download * _Nonnull download, NSUInteger idx, BOOL * _Nonnull stop) {
        [DownloadSession.sharedDownloadSession removeDownload:download];
        [download removeLocalFiles];
    }];
    
    s_sortedDownloads = nil;
    
    [self saveDownloadsDictionary];
    
    [downloads enumerateObjectsUsingBlock:^(Download * _Nonnull download, NSUInteger idx, BOOL * _Nonnull stop) {
        download.state = DownloadStateRemoved;
    }];
    
    [UserInteractionEvent removeFromDownloads:downloads];
}

+ (nullable NSProgress *)currentlyKnownProgressForDownload:(Download *)download
{
    return [DownloadSession.sharedDownloadSession currentlyKnownProgressForDownload:download];
}

#pragma mark Object lifecycle

- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder
{
    // Don't use state from AutoCoding
    _unencodableState = DownloadStateUnknown;
    [self setNeedsStateUpdateSilent:YES];
    return self;
}

- (instancetype)initWithMedia:(SRGMedia *)media
{
    if (self = [super init]) {
        self.media = media;
        self.creationDate = NSDate.date;
        self.presentation = media.presentation;
        
        [self updateWithMedia:media];
        [self setNeedsStateUpdateSilent:YES];
    }
    return self;
}

// Initializer from the plist backup
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    NSString *uid = dictionary[@"uid"];
    NSString *title = dictionary[@"title"];
    
    // At least a uid and a title must be guaranteed
    if (uid.length == 0 || title.length == 0) {
        PlayLogError(@"download", @"Missing download identifier or title");
        return nil;
    }
    
    if (self = [super init]) {
        // No object
        
        self.creationDate = dictionary[@"creationDate"] ?: NSDate.date;
        
        self.downloadImageURL = [NSURL URLWithString:dictionary[@"downloadImageURL"]];
        
        self.localMediaFileName = dictionary[@"localMediaFileName"];
        self.localImageFileName = dictionary[@"localImageFileName"];
        
        self.presentation = [dictionary[@"presentation"] integerValue];
        
        self.uid = dictionary[@"uid"];
        self.URN = dictionary[@"URN"];
        self.mediaType = [dictionary[@"mediaType"] integerValue];
        
        self.title = dictionary[@"title"];
        self.lead = dictionary[@"lead"];
        self.summary = dictionary[@"summary"];
        self.imageTitle = dictionary[@"imageTitle"];
        self.imageCopyright = dictionary[@"imageCopyright"];
        
        self.contentType = [dictionary[@"contentType"] integerValue];
        self.source = [dictionary[@"source"] integerValue];
        self.date = dictionary[@"date"];
        self.duration = [dictionary[@"duration"] integerValue];
        self.blockingReason = [dictionary[@"blockingReason"] integerValue];
        self.youthProtectionColor = [dictionary[@"youthProtectionColor"] integerValue];
        self.podcastStandardDefinitionURL = [NSURL URLWithString:dictionary[@"podcastStandardDefinitionURL"]];
        self.podcastHighDefinitionURL = [NSURL URLWithString:dictionary[@"podcastHighDefinitionURL"]];
        self.startDate = dictionary[@"startDate"];
        self.endDate = dictionary[@"endDate"];
        self.accessibilityTitle = dictionary[@"accessibilityTitle"];
        
        // Don't saved relatedContents
        // Don't saved socialCounts
        
        [self setNeedsStateUpdateSilent:YES];
    }
    return self;
}

#pragma mark Setters

- (void)updateWithMedia:(SRGMedia *)media
{
    if (! media) {
        return;
    }
    
    self.media = media;
    
    // Don't update creationDate
    // Don't update localMediaFileName
    // Don't update localImageFileName
    // Don't update state
    
    self.presentation = media.presentation;
    
    self.downloadImageURL = [SRGDataProvider.currentDataProvider URLForImage:media.image withSize:SRGImageSizeMedium scaling:SRGImageScalingDefault];
    
    self.uid = media.uid;
    self.URN = media.URN;
    self.mediaType = media.mediaType;
    
    self.title = media.title;
    self.lead = media.lead;
    self.summary = media.summary;
    self.imageTitle = media.imageTitle;
    self.imageCopyright = media.imageCopyright;
    
    self.contentType = media.contentType;
    self.source = media.source;
    self.date = media.date;
    self.duration = media.duration;
    self.blockingReason = [media blockingReasonAtDate:NSDate.date];
    self.youthProtectionColor = media.youthProtectionColor;
    self.podcastStandardDefinitionURL = media.podcastStandardDefinitionURL;
    self.podcastHighDefinitionURL = media.podcastHighDefinitionURL;
    self.startDate = media.startDate;
    self.endDate = media.endDate;
    self.accessibilityTitle = media.accessibilityTitle;
    
    // Don't copy relatedContents
    // Don't copy socialCounts
}

- (BOOL)setLocalMediaFileWithTmpFile:(NSURL *)tmpFile MIMEType:(NSString *)MIMEType
{
    NSArray *types = [MIMEType componentsSeparatedByString:@"/"];
    NSString *type = types.firstObject;
    NSString *extension = types.lastObject ?: @"mov";
    
    // Try to fix the default arbitrary binary data response with the url file extension
    if ([type.lowercaseString isEqualToString:@"application"] && [extension.lowercaseString isEqualToString:@"octet-stream"]) {
        if (self.downloadMediaURL.pathExtension != nil) {
            extension = self.downloadMediaURL.pathExtension;
        }
        else {
            PlayLogError(@"download", @"Could not find a file extension for media %@.\nMIMEType: %@", self.URN, MIMEType);
            return NO;
        }
    }
    
    // For audio, mpeg type extension don't work with AVPlayer
    if ([type.lowercaseString isEqualToString:@"audio"] && [extension.lowercaseString isEqualToString:@"mpeg"]) {
        extension = @"mp3";
    }
    
    NSString *mediaFileName = [[self.URN stringByReplacingOccurrencesOfString:@":" withString:@"-"] stringByAppendingFormat:@"-media.%@", extension];
    NSString *localURLString = [[Download downloadsDirectoryURLString] stringByAppendingPathComponent:mediaFileName];
    NSURL *localURL = [NSURL fileURLWithPath:localURLString];
    [NSFileManager.defaultManager removeItemAtURL:localURL error:nil];
    NSError *error = nil;
    if (localURL && [NSFileManager.defaultManager moveItemAtURL:tmpFile toURL:localURL error:&error] && ! error) {
        BOOL excludeFileFromBackup = [localURL setResourceValue:@YES
                                                         forKey:NSURLIsExcludedFromBackupKey
                                                          error:&error];
        PlayLogDebug(@"download", @"Downloaded file %@ is%@ excluded from iTunes/iCloud backup.%@%@",
                     mediaFileName, (excludeFileFromBackup) ? @"" : @" not",
                     (excludeFileFromBackup) ? @"" : @"\nError: ", (excludeFileFromBackup) ? @"" : error);
        self.localMediaFileName = mediaFileName;
        if ([Download downloadForMedia:self.media]) {
            [Download saveDownloadsDictionary];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNeedsStateUpdate];
        });
        return YES;
    }
    else {
        PlayLogError(@"download", @"Could not save the downloaded file for media %@.\nError: %@", self.URN, error);
    }
    return NO;
}

- (BOOL)setLocalImageFileWithTmpFile:(NSURL *)tmpFile MIMEType:(NSString *)MIMEType
{
    NSString *extension = [MIMEType componentsSeparatedByString:@"/"].lastObject ?: @"jpg";
    NSString *imageFileName = [[self.URN stringByReplacingOccurrencesOfString:@":" withString:@"-"] stringByAppendingFormat:@"-image.%@", extension];
    NSString *localURLString = [[Download downloadsDirectoryURLString] stringByAppendingPathComponent:imageFileName];
    NSURL *localURL = [NSURL fileURLWithPath:localURLString];
    [NSFileManager.defaultManager removeItemAtURL:localURL error:nil];
    NSError *error = nil;
    if (localURL && [NSFileManager.defaultManager moveItemAtURL:tmpFile toURL:localURL error:&error] && ! error) {
        self.localImageFileName = imageFileName;
        if ([Download downloadForMedia:self.media]) {
            [Download saveDownloadsDictionary];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNeedsStateUpdate];
        });
        return YES;
    }
    else {
        PlayLogError(@"download", @"Could not save the downloaded file for media %@.\nError: %@", self.URN, error);
    }
    return NO;
}

- (void)removeLocalFiles
{
    NSError *error;
    if (self.localMediaFileURL) {
        [NSFileManager.defaultManager removeItemAtURL:self.localMediaFileURL error:&error];
        self.localMediaFileName = nil;
    }
    if (self.localImageFileURL) {
        [NSFileManager.defaultManager removeItemAtURL:self.localImageFileURL error:&error];
        self.localImageFileName = nil;
    }
}

@synthesize state = _unencodableState;

- (void)setState:(DownloadState)state
{
    if (_unencodableState == state) {
        return;
    }
    
    _unencodableState = state;
    
    [NSNotificationCenter.defaultCenter postNotificationName:DownloadStateDidChangeNotification
                                                      object:self
                                                    userInfo:@{DownloadStateKey : @(state)}];
}

- (void)setNeedsStateUpdate
{
    [self setNeedsStateUpdateSilent:NO];
}

- (void)setNeedsStateUpdateSilent:(BOOL)silent
{
    DownloadState downloadState = DownloadStateUnknown;
    
    if (self.localMediaFileURL) {
        downloadState = DownloadStateDownloaded;
    }
    else if ([DownloadSession.sharedDownloadSession isDownloadingDownload:self]) {
        downloadState = DownloadStateDownloading;
    }
    else if ([DownloadSession.sharedDownloadSession hasTasksForDownload:self]) {
        downloadState = DownloadStateDownloadingSuspended;
    }
    else if ([Download downloadForMedia:self.media]) {
        downloadState = DownloadStateAdded;
    }
    else if ([Download canDownloadMedia:self.media]) {
        downloadState = DownloadStateDownloadable;
    }
    
    if (silent) {
        _unencodableState = downloadState;
    }
    else {
        self.state = downloadState;
    }
}

#pragma mark Getters

- (NSDictionary *)backupDictionary
{
    // Don't set NSNull object in the dictionary, for a plist serialization
    NSMutableDictionary *backupDictionary = [NSMutableDictionary dictionary];
    if (self.creationDate)
        backupDictionary[@"creationDate"] = self.creationDate;
    
    if (self.downloadImageURL) {
        backupDictionary[@"downloadImageURL"] = self.downloadImageURL.absoluteString;
    }
    
    if (self.localMediaFileName)
        backupDictionary[@"localMediaFileName"] = self.localMediaFileName;
    if (self.localImageFileName)
        backupDictionary[@"localImageFileName"] = self.localImageFileName;
    
    backupDictionary[@"presentation"] = @(self.presentation);
    
    if (self.uid)
        backupDictionary[@"uid"] = self.uid;
    if (self.URN)
        backupDictionary[@"URN"] = self.URN;
    backupDictionary[@"mediaType"] = @(self.mediaType);
    
    if (self.title)
        backupDictionary[@"title"] = self.title;
    if (self.lead)
        backupDictionary[@"lead"] = self.lead;
    if (self.summary)
        backupDictionary[@"summary"] = self.summary;
    if (self.imageTitle)
        backupDictionary[@"imageTitle"] = self.imageTitle;
    if (self.imageCopyright)
        backupDictionary[@"imageCopyright"] = self.imageCopyright;
    
    backupDictionary[@"contentType"] = @(self.contentType);
    backupDictionary[@"source"] = @(self.source);
    if (self.date)
        backupDictionary[@"date"] = self.date;
    backupDictionary[@"duration"] = @(self.duration);
    backupDictionary[@"blockingReason"] = @(self.blockingReason);
    backupDictionary[@"youthProtectionColor"] = @(self.youthProtectionColor);
    if (self.podcastStandardDefinitionURL.absoluteString)
        backupDictionary[@"podcastStandardDefinitionURL"] = self.podcastStandardDefinitionURL.absoluteString;
    if (self.podcastHighDefinitionURL.absoluteString)
        backupDictionary[@"podcastHighDefinitionURL"] = self.podcastHighDefinitionURL.absoluteString;
    if (self.startDate)
        backupDictionary[@"startDate"] = self.startDate;
    if (self.endDate)
        backupDictionary[@"endDate"] = self.endDate;
    if (self.accessibilityTitle)
        backupDictionary[@"accessibilityTitle"] = self.accessibilityTitle;
    
    // Don't save relatedContents
    // Don't save socialCounts
    
    return backupDictionary.copy;
}

- (NSDictionary *)mediaDictionary
{
    NSMutableDictionary *mediaDictionary = [NSMutableDictionary dictionary];
    
    if (self.uid && [self.uid isKindOfClass:NSString.class])
        mediaDictionary[@"uid"] = self.uid;
    if (self.URN && [self.URN isKindOfClass:NSString.class])
        mediaDictionary[@"URN"] = self.URN;
    mediaDictionary[@"mediaType"] = @(self.mediaType);
    
    if (self.title && [self.title isKindOfClass:NSString.class])
        mediaDictionary[@"title"] = self.title;
    if (self.lead && [self.lead isKindOfClass:NSString.class])
        mediaDictionary[@"lead"] = self.lead;
    if (self.summary && [self.summary isKindOfClass:NSString.class])
        mediaDictionary[@"summary"] = self.summary;
    if (self.localImageFileURL && [self.localImageFileURL isKindOfClass:NSURL.class])
        mediaDictionary[@"imageURL"] = self.localImageFileURL;
    if (self.imageTitle && [self.imageTitle isKindOfClass:NSString.class])
        mediaDictionary[@"imageTitle"] = self.imageTitle;
    if (self.imageCopyright && [self.imageCopyright isKindOfClass:NSString.class])
        mediaDictionary[@"imageCopyright"] = self.imageCopyright;
    
    mediaDictionary[@"contentType"] = @(self.contentType);
    mediaDictionary[@"source"] = @(self.source);
    if (self.date && [self.date isKindOfClass:NSDate.class])
        mediaDictionary[@"date"] = self.date;
    mediaDictionary[@"duration"] = @(self.duration);
    mediaDictionary[@"originalBlockingReason"] = @(self.blockingReason);
    mediaDictionary[@"youthProtectionColor"] = @(self.youthProtectionColor);
    if (self.podcastStandardDefinitionURL && [self.podcastStandardDefinitionURL isKindOfClass:NSURL.class])
        mediaDictionary[@"podcastStandardDefinitionURL"] = self.podcastStandardDefinitionURL;
    if (self.podcastHighDefinitionURL && [self.podcastHighDefinitionURL isKindOfClass:NSURL.class])
        mediaDictionary[@"podcastHighDefinitionURL"] = self.podcastHighDefinitionURL;
    if (self.startDate && [self.startDate isKindOfClass:NSDate.class])
        mediaDictionary[@"startDate"] = self.startDate;
    if (self.endDate && [self.endDate isKindOfClass:NSDate.class])
        mediaDictionary[@"endDate"] = self.endDate;
    if (self.accessibilityTitle && [self.accessibilityTitle isKindOfClass:NSString.class])
        mediaDictionary[@"accessibilityTitle"] = self.accessibilityTitle;
    
    return mediaDictionary.copy;
}

- (SRGBlockingReason)blockingReasonAtDate:(NSDate *)date
{
    return [self.media blockingReasonAtDate:date];
}

- (SRGTimeAvailability)timeAvailabilityAtDate:(NSDate *)date
{
    return [self.media timeAvailabilityAtDate:date];
}

- (BOOL)isPlayableAbroad
{
    return YES;
}

- (NSArray<SRGRelatedContent *> *)relatedContents
{
    return nil;
}

- (NSArray<SRGSocialCount *> *)socialCounts
{
    return nil;
}

- (SRGImage *)image
{
    return [SRGImage imageWithURL:self.localImageFileURL variant:SRGImageVariantDefault];
}

- (NSURL *)downloadMediaURL
{
    return self.podcastHighDefinitionURL ?: self.podcastStandardDefinitionURL;
}

- (NSURL *)localMediaFileURL
{
    if (!self.localMediaFileName) {
        return nil;
    }
    
    NSString *mediaFilePath = [[Download downloadsDirectoryURLString] stringByAppendingPathComponent:self.localMediaFileName];
    if ([NSFileManager.defaultManager fileExistsAtPath:mediaFilePath]) {
        return [NSURL fileURLWithPath:mediaFilePath];
    }
    else {
        return nil;
    }
}

- (NSURL *)localImageFileURL
{
    if (!self.localImageFileName) {
        return nil;
    }
    
    NSString *imageFilePath = [[Download downloadsDirectoryURLString] stringByAppendingPathComponent:self.localImageFileName];
    if ([NSFileManager.defaultManager fileExistsAtPath:imageFilePath]) {
        return [NSURL fileURLWithPath:imageFilePath];
    }
    else {
        return nil;
    }
}

- (long long)size
{
    if (! self.localMediaFileURL) {
        return 0;
    }
    
    NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:self.localMediaFileURL.path error:NULL];
    NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
    return [fileSize longLongValue];
}

- (SRGMedia *)media
{
    if (!_media) {
        NSError *error = nil;
        _media = [[SRGMedia alloc] initWithDictionary:self.mediaDictionary error:&error];
        if (!_media) {
            PlayLogError(@"download", @"Could not create media from dictionary. Reason: %@", error);
            NSAssert(NO, @"Could not create media from download backup dictionary. Not safe. See error above.");
        }
    }
    
    if (! [FXReachability sharedInstance].reachable) {
        NSMutableDictionary *offlineMediaDictionary = _media.dictionaryValue.mutableCopy;
        offlineMediaDictionary[@"imageURL"] = self.localImageFileURL;
        
        NSError *error = nil;
        SRGMedia *offlineMedia = [[SRGMedia alloc] initWithDictionary:offlineMediaDictionary error:nil];
        if (!offlineMedia) {
            PlayLogError(@"download", @"Could not create media from modify offline dictionary. Reason: %@", error);
            NSAssert(NO, @"Could not create media from modify offline dictionary. Not safe. See error above.");
        }
        return offlineMedia;
    }
    else {
        return _media;
    }
}

- (DownloadState)state
{
    [self setNeedsStateUpdateSilent:NO];
    return _unencodableState;
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; URN = %@, media = %@; date = %@>",
            self.class,
            self,
            self.URN,
            self.media,
            self.date];
}

@end
