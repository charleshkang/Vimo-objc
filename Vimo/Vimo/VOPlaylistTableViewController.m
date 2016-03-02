//
//  VOPlaylistTableViewController.m
//  Vimo
//
//  Created by Charles Kang on 2/26/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "VOPlaylistTableViewController.h"
#import "VOCustomTableViewCell.h"
#import "VOMusicPlayerViewController.h"
#import "VOUser.h"

#import <Spotify/Spotify.h>

@interface VOPlaylistTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) VOUser *user;

@property (nonatomic) NSInteger currentSongIndex;

@property (nonatomic) VOPlaylistTableViewController *musicVC;
@property (nonatomic) VOMusicPlayerViewController *musicPlayerVC;

@property (nonatomic) SPTPlaylistSnapshot *currentPlaylist;
@property (nonatomic) NSMutableArray *trackURIs;
@property (nonatomic) SPTTrack *currentTrack;
@property (nonatomic) SPTArtist *currentArtist;
@property (nonatomic) SPTPartialAlbum *album;
@property (nonatomic) UIImageView *coverArt;

@end

@implementation VOPlaylistTableViewController

@dynamic tableView;

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.title = @"Your Playlists";
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 15.0;
    
    // grab the nib from the main bundle
    UINib *nib = [UINib nibWithNibName:@"VOCustomTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellIdentifier"];
    self.playlists = [[NSMutableArray alloc] init];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.currentSongIndex = -1;
    
    self.user = [VOUser user];
    self.playlists = [NSMutableArray new];
    
    [self reloadWithPlaylists];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.playlists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VOCustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    
    NSString *playlistName;
    SPTPartialPlaylist *partialPlaylist = [self.playlists objectAtIndex:indexPath.row];
    playlistName = partialPlaylist.name;
    NSLog(@"Playlists: %@", playlistName);
    [cell.playlistLabel setText:playlistName];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!self.musicPlayerVC){
        self.musicPlayerVC = [VOMusicPlayerViewController new];
    }
    
    VOMusicPlayerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"musicPlayerVC"];
    
    if (self.currentSongIndex != indexPath.row) {
        self.currentSongIndex = indexPath.row;
        self.musicPlayerVC.session = self.user.spotifySession;
        [self.musicPlayerVC setPlaylistWithPartialPlaylist:(SPTPartialPlaylist *)[self.playlists objectAtIndex:indexPath.row]];
        NSLog(@"Selected Playlist: %@", [self.playlists objectAtIndex:indexPath.row]);
    }
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Spotify Playlist Implementation

- (void)fetchPlaylistPageForSession:(SPTSession *)session error:(NSError *)error object:(id)object
{
    if (error) {
        NSLog(@"Error fetching playlists, %@", error);
    } else {
        if ([object isKindOfClass:[SPTPlaylistList class]]) {
            SPTPlaylistList *playlistList = (SPTPlaylistList *)object;
            
            for (SPTPartialPlaylist *playlist in playlistList.items) {
                [self.playlists addObject:playlist];
            }
            [self.tableView reloadData];
        }
    }
}

- (void)reloadWithPlaylists
{
    [SPTRequest playlistsForUserInSession:self.user.spotifySession callback:^(NSError *error, id object) {
        [self fetchPlaylistPageForSession:self.user.spotifySession error:error object:object];
    }];
}

@end
