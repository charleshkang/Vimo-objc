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

@property (nonatomic) BOOL isPlaying;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;

@property (nonatomic) UIImage *playImage;
@property (nonatomic) UIImage *pauseImage;

@property (nonatomic) SPTPlaylistSnapshot *currentPlaylist;
@property (nonatomic) SPTPlayOptions *trackIndex;
@property (nonatomic) NSMutableArray *trackURIs;
@property (nonatomic) SPTTrack *currentTrack;
@property (nonatomic) SPTArtist *currentArtist;
@property (nonatomic) NSInteger currentSongIndex;

@property (weak, nonatomic) IBOutlet UIImageView *songImageView;
@property (weak, nonatomic) IBOutlet UILabel *songNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistNameLabel;
@end

@implementation VOMusicPlayerViewController

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Player";
    
    self.isPlaying = NO;
    self.trackURIs = [NSMutableArray new];
    self.currentSongIndex = 0;
    
    self.playImage = [UIImage imageNamed:@"play"];
    self.pauseImage = [UIImage imageNamed:@"pause"];
    [self.playPauseButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
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

- (void)handleNewSession
{
    SPTPlayOptions *trackIndex;
    if ([self.currentTrack.album.covers count] > 0) {
        SPTImage* image = self.currentTrack.album.largestCover;
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSData * data = [[NSData alloc] initWithContentsOfURL: image.imageURL];
            if ( data == nil ){
                NSLog(@"Image of track %@ has no data", self.currentTrack.name);
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.songImageView.image = [UIImage imageWithData:data];
                NSLog(@"Data:%@", image.imageURL);
            });
        });
    }
    
    SPTAuth *auth = [SPTAuth defaultInstance];
    //    self.currentSongIndex = 0;
    if (self.audioPlayer == nil) {
        self.audioPlayer = [[SPTAudioStreamingController alloc] initWithClientId:auth.clientID];
        self.audioPlayer.playbackDelegate = self;
        SPTVolume volume = 1.0;
        [self.audioPlayer setVolume:volume callback:^(NSError *error) {
        }];
    }
    [self.audioPlayer loginWithSession:auth.session callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
        [self.audioPlayer playURIs:self.trackURIs withOptions:(SPTPlayOptions *)trackIndex callback:^(NSError *error) {
            if(error != nil){
                NSLog(@"Error: %@", error);
                return;
            }
            self.currentTrack = [self.currentPlaylist.tracksForPlayback objectAtIndex:self.currentSongIndex];
            self.songNameLabel.text = self.currentTrack.name;
            SPTPartialArtist *artist = (SPTPartialArtist *)[self.currentTrack.artists objectAtIndex:self.currentSongIndex];
            self.artistNameLabel.text = artist.name;
            
        }
        
        ];}
     
     ];
}
- (void)togglePlaying:(id)sender
{
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer setIsPlaying:NO callback:^(NSError *error) {
        }];
        self.isPlaying = nil;
        [_playPauseButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    } else {
        [self.audioPlayer setIsPlaying:YES callback:^(NSError *error) {
        }];
        [_playPauseButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
}

- (IBAction)nextButtonTapped:(id)sender
{
    [self.audioPlayer skipNext:^(NSError *error) {
    }];
}

- (IBAction)previousButtonTapped:(id)sender
{
    [self.audioPlayer skipPrevious:^(NSError *error) {
    }];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didStartPlayingTrack:(NSURL *)trackUri
{
    NSLog(@"started track");
    self.currentSongIndex = self.audioPlayer.currentTrackIndex;
    [self.playPauseButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
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
                    self.songImageView.image = image;
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

#pragma mark - Music Player Methods

- (IBAction)playPauseButtonTapped:(UIButton *)sender
{
    
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying
{
    NSLog(@"is playing = %d", isPlaying);
}

@end
