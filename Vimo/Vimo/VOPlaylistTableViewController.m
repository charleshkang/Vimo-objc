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
#import "VOLoginVC.h"
#import "VOUser.h"

#import <Spotify/Spotify.h>

@interface VOPlaylistTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) VOUser *user;

@property (nonatomic) NSInteger currentSongIndex;

@property (nonatomic) VOPlaylistTableViewController *VOMusicVC;
@property (nonatomic) VOMusicPlayerViewController *musicPlayerVC;

@property (nonatomic) SPTPlaylistSnapshot *currentPlaylist;
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
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 20.0;
    [self navBarLogic];
    
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

#pragma mark - Table View Methods

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
    
    SPTPartialPlaylist *playlistTitles = [self.playlists objectAtIndex:indexPath.row];
    
    playlistName = playlistTitles.name;
    
    [cell.playlistLabel setText:playlistName];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VOMusicPlayerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"musicPlayerVC"];
    vc.partialPlaylist = [self.playlists objectAtIndex:indexPath.row];
    if (self.currentSongIndex != indexPath.row) {
        self.currentSongIndex = indexPath.row;
        vc.session = self.user.spotifySession;
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

#pragma mark - Logout Logic

- (IBAction)logoutButton:(id)sender
{
    SPTAuth *auth = [SPTAuth defaultInstance];
    [self.playlists removeAllObjects];
    self.currentSongIndex = -1;
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    [self.tableView reloadData];
    
    if (self.musicPlayerVC.audioPlayer) {
        [self.musicPlayerVC.audioPlayer logout:^(NSError *error) {
            auth.session = nil;
            self.musicPlayerVC = nil;
        }];
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.musicPlayerVC = nil;
            VOLoginVC *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"loginVC"];
            UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:loginVC];
            [self presentViewController:navigationController animated:YES completion:nil];
            auth.session = nil;
//            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//            [defaults setValue:auth.sessionUserDefaultsKey forKey:@"userLoggedOut"];
//            [defaults synchronize];
            NSLog(@"session: %@", auth.session);
        });
    }
}

#pragma mark - Nav Bar Logic

- (void)navBarLogic
{
    self.navigationItem.hidesBackButton = YES;
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
}

@end
