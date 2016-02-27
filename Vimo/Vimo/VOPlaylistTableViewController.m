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
<
SPTAudioStreamingDelegate
>

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
    [self handleNewSession];
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
    
//    if ([self.currentTrack.album.covers count] > 0) {
//        SPTImage* image = self.currentTrack.album.largestCover;
//        dispatch_async(dispatch_get_global_queue(0,0), ^{
//            NSData * data = [[NSData alloc] initWithContentsOfURL: image.imageURL];
//            if ( data == nil ){
//                NSLog(@"Image of track %@ has no data", self.currentTrack.name);
//                return;
//            }
//            dispatch_async(dispatch_get_main_queue(), ^{
//                cell.playlistCoverImage.image = [UIImage imageWithData: data];
//            });
//        });
//    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
     VOMusicPlayerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"musicPlayerVC"];
    
    [self.navigationController pushViewController:vc animated:YES];
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


-(void)handleNewSession {
    SPTAuth *auth = [SPTAuth defaultInstance];
    self.currentSongIndex = 0;
    if (self.audioPlayer == nil) {
        self.audioPlayer = [[SPTAudioStreamingController alloc] initWithClientId:auth.clientID];
        SPTVolume volume = 0.5;
        [self.audioPlayer setVolume:volume callback:^(NSError *error) {
            
        }];
        //self.audioPlayer.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 64];
    }
    
    [self.audioPlayer loginWithSession:auth.session callback:^(NSError *error) {
        
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
    }
     ];}

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
