//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DownloadFooterSectionView.h"
#import "Download.h"
#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface DownloadFooterSectionView ()

@property (nonatomic) long long totalFilesSize;
@property (nonatomic) long long totalFreeSpaceSize;
@property (nonatomic) NSMutableDictionary<NSString *, NSProgress *> *progresses;

@property (nonatomic, weak) IBOutlet UIView *mainView;
@property (nonatomic, weak) IBOutlet UILabel *centerLabel;

@end

@implementation DownloadFooterSectionView

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.totalFilesSize = 0;
        self.progresses = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.mainView.backgroundColor = UIColor.play_blackColor;
    
    self.centerLabel.textColor = UIColor.whiteColor;
    self.centerLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
}

- (void)willMoveToWindow:(UIWindow *)window
{
    [super willMoveToWindow:window];
    
    if (window) {
        [self updateTotalFileSizeWithUpdatedDownload:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(downloadStateDidChange:)
                                                   name:DownloadStateDidChangeNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(downloadProgressDidChange:)
                                                   name:DownloadProgressDidChangeNotification
                                                 object:nil];
    }
    else {
        [NSNotificationCenter.defaultCenter removeObserver:self name:DownloadStateDidChangeNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:DownloadProgressDidChangeNotification object:nil];
    }
}

- (void)updateTotalFileSizeWithUpdatedDownload:(Download *)download
{
    // Remove unused progresses
    [self.progresses.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull URN, NSUInteger idx, BOOL * _Nonnull stop) {
        Download *download = [Download downloadForURN:URN];
        if (!download || download.size) {
            self.progresses[URN] = nil;
        }
    }];
    
    // Total size is sum of downloaded file, plus current downloading files
    long long totalFilesSize = [[Download.downloads valueForKeyPath:@"@sum.size"] longLongValue];
    long long totalDownloadingFilesSize = [[self.progresses.allValues valueForKeyPath:@"@sum.completedUnitCount"] longLongValue];
    totalFilesSize += totalDownloadingFilesSize;
    self.totalFilesSize = totalFilesSize;
    
    NSString *totalFreeSpaceString = @"";
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [NSFileManager.defaultManager attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    static dispatch_once_t s_onceToken;
    static NSByteCountFormatter *s_byteCountFormatter;
    dispatch_once(&s_onceToken, ^{
        s_byteCountFormatter = [[NSByteCountFormatter alloc] init];
        s_byteCountFormatter.zeroPadsFractionDigits = YES;
    });
    
    if (dictionary && !error) {
        NSNumber *totalFreeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        self.totalFreeSpaceSize = [totalFreeFileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpaceString = [s_byteCountFormatter stringFromByteCount:self.totalFreeSpaceSize];
    }
    
    NSString *stringSeparator = @"\n";
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        stringSeparator = @" - ";
    }
    
    NSString *totalFileSizeString = [s_byteCountFormatter stringFromByteCount:totalFilesSize];
    self.centerLabel.text = (Download.downloads.count > 0) ? [NSString stringWithFormat:@"%@%@%@",
                                                              [NSString stringWithFormat:NSLocalizedString(@"Total space used: %@", @"Total space size, display at the bottom of download list"), totalFileSizeString],
                                                              stringSeparator,
                                                              [NSString stringWithFormat:NSLocalizedString(@"Free space: %@", @"Total free space size, display at the bottom of download list"), totalFreeSpaceString]] : @"";
}

#pragma mark Notifications

- (void)downloadStateDidChange:(NSNotification *)notification
{
    [self updateTotalFileSizeWithUpdatedDownload:notification.object];
}

- (void)downloadProgressDidChange:(NSNotification *)notification
{
    Download *download = (Download *)notification.object;
    NSProgress *progress = notification.userInfo[DownloadProgressKey];
    self.progresses[download.URN] = progress;
    [self updateTotalFileSizeWithUpdatedDownload:download];
}

@end
