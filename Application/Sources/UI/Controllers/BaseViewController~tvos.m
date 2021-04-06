//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseViewController.h"

static void commonInit(BaseViewController *self);

@implementation BaseViewController

#pragma mark Object lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Subclassing hooks

- (void)updateForContentSizeCategory
{}

#pragma mark Notifications

- (void)baseViewController_contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self updateForContentSizeCategory];
}

@end

static void commonInit(BaseViewController *self)
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(baseViewController_contentSizeCategoryDidChange:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}
