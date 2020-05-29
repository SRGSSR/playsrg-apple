//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SongsViewController.h"

#import "ChannelService.h"
#import "SongTableViewCell.h"
#import "SRGProgramComposition+PlaySRG.h"
#import "TableView.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@interface SongsViewController ()

@property (nonatomic) SRGChannel *channel;
@property (nonatomic) SRGVendor vendor;

@property (nonatomic) NSArray<SRGSong *> *songs;
@property (nonatomic, weak) TableView *tableView;

@property (nonatomic) id channelRegistration;

@end

@implementation SongsViewController

#pragma mark Object lifecycle

- (instancetype)initWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor
{
    if (self = [super init]) {
        self.channel = channel;
        self.vendor = vendor;
    }
    return self;
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
    
    if (self.play_isMovingToParentViewController) {
        self.channelRegistration = [ChannelService.sharedService addObserver:self forSongUpdatesWithChannel:self.channel vendor:self.vendor block:^(NSArray<SRGSong *> * _Nullable songs) {
            if (songs) {
                self.songs = songs;
                [self.tableView reloadData];
            }
        }];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.play_isMovingFromParentViewController) {
        [ChannelService.sharedService removeObserver:self.channelRegistration];
    }
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.songs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(SongTableViewCell.class)];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(SongTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.song = self.songs[indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SRGSong *song = self.songs[indexPath.row];
    
    // TODO: Should be associated with the main screen player directly
    SRGLetterboxController *controller = SRGLetterboxService.sharedService.controller;
    [controller seekToPosition:[SRGPosition positionAtDate:PlayStreamDate(song.date, controller)] withCompletionHandler:^(BOOL finished) {
        [controller play];
    }];
}

@end
