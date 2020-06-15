//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SongsViewController.h"

#import "ApplicationConfiguration.h"
#import "ForegroundTimer.h"
#import "Layout.h"
#import "SongTableViewCell.h"
#import "SRGProgramComposition+PlaySRG.h"
#import "TableView.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>

@interface SongsViewController ()

@property (nonatomic) SRGChannel *channel;
@property (nonatomic) ForegroundTimer *updateTimer;
@property (nonatomic, weak) SRGLetterboxController *letterboxController;

@end

@implementation SongsViewController

#pragma mark Object lifecycle

- (instancetype)initWithChannel:(SRGChannel *)channel letterboxController:(SRGLetterboxController *)letterboxController
{
    if (self = [super init]) {
        self.channel = channel;
        self.letterboxController = letterboxController;
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Songs", @"Song list title");
}

- (void)setDateInterval:(NSDateInterval *)dateInterval
{
    _dateInterval = dateInterval;
    [self.tableView reloadData];
    [self updateSelectionForCurrentSong];
}

- (void)setUpdateTimer:(ForegroundTimer *)updateTimer
{
    [_updateTimer invalidate];
    _updateTimer = updateTimer;
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.play_cardGrayBackgroundColor;
        
    TableView *tableView = [[TableView alloc] initWithFrame:view.bounds];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:tableView];
    self.tableView = tableView;
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *cellIdentifier = NSStringFromClass(SongTableViewCell.class);
    UINib *cellNib = [UINib nibWithNibName:cellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    @weakify(self)
    self.updateTimer = [ForegroundTimer timerWithTimeInterval:30. repeats:YES block:^(ForegroundTimer * _Nonnull timer) {
        @strongify(self)
        [self refresh];
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.updateTimer = nil;
}

#pragma mark Overrides

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider radioSongsForVendor:self.channel.vendor channelUid:self.channel.uid withCompletionBlock:completionHandler] requestWithPageSize:applicationConfiguration.pageSize] requestWithPage:page];
    [requestQueue addRequest:request resume:YES];
}

- (void)refreshDidFinishWithError:(NSError *)error
{
    [super refreshDidFinishWithError:error];
    
    [self updateSelectionForCurrentSong];
}

#pragma mark UI

- (void)scrollToSongAtDate:(NSDate *)date animated:(BOOL)animated
{
    if (! date) {
        return;
    }
    
    if (self.tableView.dragging) {
        return;
    }
    
    void (^animations)(void) = ^{
        NSIndexPath *indexPath = [self nearestSongIndexPathForDate:date];
        if (indexPath) {
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
        }
    };
    
    if (animated) {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.2 animations:^{
            animations();
            [self.view layoutIfNeeded];
        }];
    }
    else {
        animations();
    }
}

- (NSIndexPath *)indexPathForSongAtDate:(NSDate *)date
{
    for (SRGSong *song in self.items) {
        NSTimeInterval durationInSeconds = song.duration / 1000.;
        if (durationInSeconds <= 0.) {
            continue;
        }
        
        NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:song.date duration:durationInSeconds];
        if ([dateInterval containsDate:date]) {
            NSUInteger row = [self.items indexOfObject:song];
            return [NSIndexPath indexPathForRow:row inSection:0];
        }
    }
    return nil;
}

- (NSIndexPath *)nearestSongIndexPathForDate:(NSDate *)date
{
    if (self.items.count == 0) {
        return nil;
    }
    
    // Consider songs from the oldest to the newest one
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGSong.new, date) ascending:YES];
    NSArray<SRGSong *> *songs = [self.items sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    // Find the nearest item in the list
    __block NSUInteger nearestIndex = 0;
    [songs enumerateObjectsUsingBlock:^(SRGSong * _Nonnull song, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([date compare:song.date] == NSOrderedAscending) {
            nearestIndex = (idx > 0) ? idx - 1 : 0;
            *stop = YES;
        }
        else {
            nearestIndex = idx;
        }
    }];
    
    SRGSong *nearestSong = songs[nearestIndex];
    NSUInteger row = [self.items indexOfObject:nearestSong];
    return [NSIndexPath indexPathForRow:row inSection:0];
}

- (void)updateSelectionForSongAtDate:(NSDate *)date
{
    if (! date) {
        return;
    }
    
    NSIndexPath *indexPath = [self indexPathForSongAtDate:date];
    if (indexPath) {
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    else {
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        if (indexPath){
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)updateSelectionForCurrentSong
{
    [self updateSelectionForSongAtDate:self.letterboxController.currentDate];
}

#pragma mark ContentInsets protocol

- (UIEdgeInsets)play_paddingContentInsets
{
    return LayoutStandardTableViewPaddingInsets;
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(SongTableViewCell.class)];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(SongTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SRGSong *song = self.items[indexPath.row];
    cell.song = song;
    cell.playing = (self.letterboxController.playbackState == SRGMediaPlayerPlaybackStatePlaying);
    cell.enabled = [self.dateInterval containsDate:song.date];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SRGSong *song = self.items[indexPath.row];
    CGFloat height = [SongTableViewCell heightForSong:song withCellWidth:CGRectGetWidth(tableView.frame)];
    return LayoutTableTopAlignedCellHeight(height, 20.f, indexPath.row, self.items.count);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SongTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (! cell.enabled) {
        return;
    }
    
    SRGSong *song = self.items[indexPath.row];
    [self.letterboxController seekToPosition:[SRGPosition positionAtDate:song.date] withCompletionHandler:^(BOOL finished) {
        [self.letterboxController play];
    }];
}

@end
