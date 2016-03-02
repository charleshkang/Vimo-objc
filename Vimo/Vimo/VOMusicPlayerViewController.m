//
//  VOMusicPlayerViewController.m
//  Vimo
//
//  Created by Charles Kang on 2/27/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "VOMusicPlayerViewController.h"
#import "VOKeys.h"
#import "VOUser.h"

@interface VOMusicPlayerViewController ()
<
SPTAudioStreamingDelegate
>

@property (nonatomic) UIImage *playImage;
@property (nonatomic) UIImage *pauseImage;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (nonatomic) SPTPlaylistSnapshot *currentPlaylist;
@property (nonatomic) SPTPlayOptions *trackIndex;
@property (nonatomic) NSMutableArray *trackURIs;
@property (nonatomic) SPTTrack *currentTrack;
@property (nonatomic) SPTArtist *currentArtist;
@property (nonatomic) NSInteger currentSongIndex;
@property (nonatomic) SPTAudioStreamingController *audioPlayer;

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;

@end

@implementation VOMusicPlayerViewController

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleLabel.text = @"Nothing Playing";
    self.artistLabel.text = @"";
    self.currentSongIndex = 0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self handleNewSession];
}

#pragma mark - Spotify Player Methods

- (void)setPlaylistWithPartialPlaylist:(SPTPartialPlaylist *)partialPlaylist
{
    if(partialPlaylist) {
        [SPTRequest requestItemAtURI:partialPlaylist.uri withSession:self.session callback:^(NSError *error, id object) {
            if([object isKindOfClass:[SPTPlaylistSnapshot class]]){
                self.currentPlaylist = (SPTPlaylistSnapshot *)object;
                [self.trackURIs removeAllObjects];
                NSLog(@"Playlist Size: %lu", (unsigned long)self.currentPlaylist.trackCount);
                unsigned int i = 0;
                if(self.currentPlaylist.trackCount > 0){
                    for(SPTTrack *track in self.currentPlaylist.tracksForPlayback){
                        NSLog(@"Got Songs:%u %@ ", i, track.name);
                        i++;
                        [self.trackURIs addObject:track.uri];
                    }
                    [self handleNewSession];
                }
            }
        }];
    }
}

- (void)handleNewSession {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (self.audioPlayer == nil) {
        self.audioPlayer = [[SPTAudioStreamingController alloc] initWithClientId:auth.clientID];
        self.audioPlayer.playbackDelegate = self;
        self.audioPlayer.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 64];
    }
    
    [self.audioPlayer loginWithSession:auth.session callback:^(NSError *error) {
        
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
        
        [self updateUI];
        
        NSURLRequest *playlistReq = [SPTPlaylistSnapshot createRequestForPlaylistWithURI:[NSURL URLWithString:@"spotify:user:cariboutheband:playlist:4Dg0J0ICj9kKTGDyFu0Cv4"]
                                                                             accessToken:auth.session.accessToken
                                                                                   error:nil];
        
        [[SPTRequest sharedHandler] performRequest:playlistReq callback:^(NSError *error, NSURLResponse *response, NSData *data) {
            if (error != nil) {
                NSLog(@"*** Failed to get playlist %@", error);
                return;
            }
            
            SPTPlaylistSnapshot *playlistSnapshot = [SPTPlaylistSnapshot playlistSnapshotFromData:data withResponse:response error:nil];
            
            [self.audioPlayer playURIs:playlistSnapshot.firstTrackPage.items fromIndex:0 callback:nil];
        }];
    }];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didStartPlayingTrack:(NSURL *)trackUri
{
    NSLog(@"started track");
    self.currentSongIndex = self.audioPlayer.currentTrackIndex;
    [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [SPTTrack trackWithURI:trackUri session:self.session callback:^(NSError *error, SPTTrack *track) {
        self.currentTrack = track;
        NSURL *coverArtURL = self.currentTrack.album.largestCover.imageURL;
        NSLog(@"URLs: %@", self.currentTrack.album.largestCover.imageURL);
        
        if(coverArtURL){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *error = nil;
                UIImage *image = nil;
                NSData *imageData = [NSData dataWithContentsOfURL:coverArtURL options:0 error:&error];
                
                if (imageData != nil) {
                    image = [UIImage imageWithData:imageData];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.coverView.image = image;
                    if (image == nil) {
                        NSLog(@"Couldn't load cover image with error: %@", error);
                        return;
                    }
                });
            });
        }
    }
     ];
}

- (void)updateUI
{
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (self.audioPlayer.currentTrackURI == nil) {
        self.coverView.image = nil;
        return;
    }
    [SPTTrack trackWithURI:self.audioPlayer.currentTrackURI
                   session:auth.session
                  callback:^(NSError *error, SPTTrack *track) {
                      
                      self.titleLabel.text = track.name;
                      
                      SPTPartialArtist *artist = [track.artists objectAtIndex:0];
                      self.artistLabel.text = artist.name;
                      
                      NSURL *imageURL = track.album.largestCover.imageURL;
                      if (imageURL == nil) {
                          NSLog(@"Album %@ doesn't have any images!", track.album);
                          self.coverView.image = nil;
                          return;
                      }
                      
                      // Pop over to a background queue to load the image over the network.
                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                          NSError *error = nil;
                          UIImage *image = nil;
                          NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&error];
                          
                          if (imageData != nil) {
                              image = [UIImage imageWithData:imageData];
                          }
                          
                          
                          // …and back to the main queue to display the image.
                          dispatch_async(dispatch_get_main_queue(), ^{
                              self.coverView.image = image;
                              if (image == nil) {
                                  NSLog(@"Couldn't load cover image with error: %@", error);
                                  return;
                              }
                          });
                          
                      });
                      
                  }];
}


- (IBAction)playButtonTapped:(id)sender
{
    [self.audioPlayer setIsPlaying:!self.audioPlayer.isPlaying callback:nil];
    NSLog(@"Playing");
}

- (IBAction)pauseButtonTapped:(id)sender
{
    [self.audioPlayer setIsPlaying:!self.audioPlayer.isPlaying callback:nil];
    NSLog(@"Paused");
}

- (IBAction)nextButtonTapped:(id)sender
{
    [self.audioPlayer skipNext:nil];
    NSLog(@"Forward");
}

- (IBAction)previousButtonTapped:(id)sender
{
    [self.audioPlayer skipPrevious:nil];
    NSLog(@"Back");
}

#pragma mark - Track Player Delegates

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message from Spotify"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didFailToPlayTrack:(NSURL *)trackUri {
    NSLog(@"failed to play track: %@", trackUri);
}

- (void) audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    NSLog(@"track changed = %@", [trackMetadata valueForKey:SPTAudioStreamingMetadataTrackURI]);
    [self updateUI];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
    NSLog(@"is playing = %d", isPlaying);
}


@end
