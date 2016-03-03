//
//  VOMusicPlayerViewController.m
//  Vimo
//
//  Created by Charles Kang on 2/27/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "VOMusicPlayerViewController.h"
#import "VOPlaylistTableViewController.h"
#import "VOUser.h"
#import "VOKeys.h"

@interface VOMusicPlayerViewController ()
<
SPTAudioStreamingDelegate
>

@property (nonatomic) SPTPlaylistSnapshot *currentPlaylist;
@property (nonatomic) NSMutableArray *trackURIs;
@property (nonatomic) SPTArtist *currentArtist;
@property (nonatomic) NSInteger currentSongIndex;

@property (nonatomic) UIImage *playImage;
@property (nonatomic) UIImage *pauseImage;

@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;

@end

@implementation VOMusicPlayerViewController

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.trackURIs = [NSMutableArray new];
    self.currentSongIndex = 0;
    
    self.pauseImage = [UIImage imageNamed:@"pause"];
    self.playImage = [UIImage imageNamed:@"play"];
    
    [self setPlaylistWithPartialPlaylist:self.partialPlaylist];
}

#pragma mark - Spotify Player Methods

// This is fine
- (void)setPlaylistWithPartialPlaylist:(SPTPartialPlaylist *)partialPlaylist
{
    if (partialPlaylist) {
        [SPTRequest requestItemAtURI:partialPlaylist.uri withSession:self.session callback:^(NSError *error, id object) {
            if ([object isKindOfClass:[SPTPlaylistSnapshot class]]) {
                self.currentPlaylist = (SPTPlaylistSnapshot *)object;
                [self.trackURIs removeAllObjects];
                NSLog(@"Playlist Size: %lu", (unsigned long)self.currentPlaylist.trackCount);
                unsigned int i = 0;
                if (self.currentPlaylist.trackCount > 0) {
                    for (SPTTrack *track in self.currentPlaylist.tracksForPlayback) {
                        i++;
                        [self.trackURIs addObject:track.uri];
                    }
                    [self handleNewSession];
                }
            }
        }];
    }
}

- (void)handleNewSession
{
    SPTAuth *auth = [SPTAuth defaultInstance];
    self.currentSongIndex = 0;
    
    if (self.audioPlayer == nil) {
        self.audioPlayer = [[SPTAudioStreamingController alloc] initWithClientId:auth.clientID];
        self.audioPlayer.playbackDelegate = self;
        SPTVolume volume = 0.5;
        [self.audioPlayer setVolume:volume callback:^(NSError *error) {
        }];
    }
    
    [self.audioPlayer loginWithSession:auth.session callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Enabling playback error: %@", error);
            return;
        }

        [self.audioPlayer playURIs:self.trackURIs fromIndex:self.currentSongIndex callback:^(NSError *error) {
            if (error != nil) {
                NSLog(@"Error:%@", error);
                return;
            }
            
            self.currentTrack = [self.currentPlaylist.tracksForPlayback objectAtIndex:self.currentSongIndex];
            self.titleLabel.text = self.currentTrack.name;
            SPTPartialArtist *artist = (SPTPartialArtist *)[self.currentTrack.artists objectAtIndex:self.currentSongIndex];
            self.artistLabel.text = artist.name;
        }
         ];}
    ];
}

#pragma mark - Player Implementation

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Spotify Message:"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didStartPlayingTrack:(NSURL *)trackUri
{
    self.currentSongIndex = self.audioPlayer.currentTrackIndex;
    [SPTTrack trackWithURI:trackUri session:self.session callback:^(NSError *error, SPTTrack *track) {
        self.currentTrack = track;
        self.titleLabel.text = self.currentTrack.name;
        SPTPartialArtist *artist = (SPTPartialArtist *)[self.currentTrack.artists objectAtIndex:0];
        self.artistLabel.text = artist.name;
        NSURL *coverArtURL = self.currentTrack.album.largestCover.imageURL;
        
        if (coverArtURL) {
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

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying
{
    NSLog(@"is playing = %d", isPlaying);
}

- (IBAction)playPauseButtonTapped:(id)sender
{
    VOUser *controller = [VOUser user];
    if(self.audioPlayer.isPlaying){
        [self.audioPlayer setIsPlaying:NO callback:^(NSError *error) {
        }];
        [_playPauseButton setImage:self.playImage forState:UIControlStateNormal];
        
    }else{
        [self.audioPlayer setIsPlaying:YES callback:^(NSError *error) {
        }];
        [_playPauseButton setImage:self.pauseImage forState:UIControlStateNormal];
    }
    [controller.player setIsPlaying:!controller.player.isPlaying callback:nil];
}

- (IBAction)nextButtonTapped:(id)sender
{
    if(self.currentSongIndex == (self.trackURIs.count - 1) && !self.audioPlayer.shuffle) {
        self.currentSongIndex = 0;
        SPTPlayOptions *playOptions = [SPTPlayOptions new];
        playOptions.startTime = 0;
        playOptions.trackIndex = self.currentSongIndex;
        [self.audioPlayer playURIs:self.trackURIs withOptions:playOptions callback:^(NSError *error) {
            if (error != nil) {
                NSLog(@"ERROR: %@", error);
            }
        }];
    }
    [self.audioPlayer skipNext:^(NSError *error) {
        
    }];
}

- (IBAction)previousButtonTapped:(id)sender
{
    [self.audioPlayer skipPrevious:^(NSError *error) {
    }];
}

- (IBAction)backButtonTapped:(id)sender
{
    if (self.audioPlayer.isPlaying == YES) {
        [self.audioPlayer setIsPlaying:!self.audioPlayer.isPlaying callback:nil];
    }
    self.audioPlayer = nil;
    [self.navigationController popViewControllerAnimated:YES];
}


@end
