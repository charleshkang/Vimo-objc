//
//  VOPlaylistTableViewController.m
//  Vimo
//
//  Created by Charles Kang on 2/26/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "VOPlaylistTableViewController.h"
#import "VOCustomTableViewCell.h"
#import "VOUser.h"

#import <Spotify/Spotify.h>

@interface VOPlaylistTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) VOUser *user;

@property (nonatomic) NSInteger currentSongIndex;

@property (nonatomic) VOPlaylistTableViewController *musicVC;

@property (nonatomic)SPTPlaylistSnapshot *currentPlaylist;
@property (nonatomic)NSMutableArray *trackURIs;
@property (nonatomic)SPTTrack *currentTrack;
@property (nonatomic)SPTArtist *currentArtist;

@end

@implementation VOPlaylistTableViewController

@dynamic tableView;

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
//    cell.playlistLabel.text = [self.playlists objectAtIndex:indexPath.row];


    return cell;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

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
                NSLog(@"playlists: %@", playlist);
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
