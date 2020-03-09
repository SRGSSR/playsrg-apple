//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeTableViewCell.h"

@interface HomeTableViewCell ()

@property (nonatomic) HomeSectionInfo *homeSectionInfo;
@property (nonatomic, getter=isFeatured) BOOL featured;

@end

@implementation HomeTableViewCell

#pragma mark Class methods

+ (CGFloat)heightForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds featured:(BOOL)featured
{
    NSAssert(NO, @"Must be implemented in subclasses");
    return 0.f;
}

#pragma mark Overrides

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.homeSectionInfo = nil;
    self.featured = NO;
}

#pragma mark Getters and setters

- (BOOL)isEmpty
{
    return self.homeSectionInfo.items.count == 0;
}

- (void)setHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo featured:(BOOL)featured
{
    self.featured = featured;
    self.homeSectionInfo = homeSectionInfo;
}

@end
