//
//  VOMusicPlayerViewController.m
//  Vimo
//
//  Created by Charles Kang on 2/27/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "VOMusicPlayerViewController.h"
#import "VOPlaylistTableViewController.h"

@interface VOMusicPlayerViewController ()
<
SPTAudioStreamingDelegate,
SPTAudioStreamingPlaybackDelegate
>

@property (nonatomic) BOOL isPlaying;
@property (nonatomic) NSInteger currentSongIndex;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;

@property (nonatomic)UIImage *playImage;
@property (nonatomic)UIImage *pauseImage;

@property (nonatomic)SPTPlaylistSnapshot *currentPlaylist;
@property (nonatomic)NSMutableArray *trackURIs;
@property (nonatomic)SPTTrack *currentTrack;

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
    [self.playPauseButton addTarget:self action:@selector(togglePlaying:) forControlEvents:UIControlEventTouchUpInside];

}

#pragma mark - Spotify Player Methods

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didStartPlayingTrack:(NSURL *)trackUri{
    NSLog(@"started track");
    //    NSLog(@"Track Index: %d", self.audioPlayer.currentTrackIndex);
    self.currentSongIndex = self.audioPlayer.currentTrackIndex;
    [self.playPauseButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [SPTTrack trackWithURI:trackUri session:self.session callback:^(NSError *error, SPTTrack *track) {
        self.currentTrack = track;
        //        self.trackLabel.text = self.currentTrack.name;
        SPTPartialArtist *artist = (SPTPartialArtist *)[self.currentTrack.artists objectAtIndex:0];
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
//                    self.coverArt.image = image;
//                    if (image == nil) {
//                        NSLog(@"Couldn't load cover image with error: %@", error);
//                        return;
//                    }
                });
            });
        }
    }
     ];}

-(void)setPlaylistWithPartialPlaylist:(SPTPartialPlaylist *)partialPlaylist
{
    if(partialPlaylist) {
        [SPTRequest requestItemAtURI:partialPlaylist.uri withSession:self.session callback:^(NSError *error, id object) {
            if([object isKindOfClass:[SPTPlaylistSnapshot class]]){
                self.currentPlaylist = (SPTPlaylistSnapshot *)object;
                [self.trackURIs removeAllObjects];
                NSLog(@"PLAYLIST SIZE: %lu", (unsigned long)self.currentPlaylist.trackCount);
                unsigned int i = 0;
                if(self.currentPlaylist.trackCount > 0){
                    for(SPTTrack *track in self.currentPlaylist.tracksForPlayback){
                        NSLog(@"GOT SONG:%u %@ ", i, track.name);
                        i++;
                        [self.trackURIs addObject:track.uri];
                    }
                    [self handleNewSession];
                }
            }
        }];
    }
}

-(void)handleNewSession
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
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
        [self.audioPlayer playURIs:self.trackURIs fromIndex:self.currentSongIndex callback:^(NSError *error) {
            if(error != nil){
                NSLog(@"ERROR");
                return;
            }
            NSLog(@"TRACK DURATION: %f", self.audioPlayer.currentTrackDuration);
            
        }];
    }];
}

#pragma mark - Music Player Methods

- (IBAction)playPauseButtonTapped:(UIButton *)sender
{
}

-(void)togglePlaying:(id)sender
{
    NSLog(@"Current playback: %f", self.audioPlayer.currentPlaybackPosition);
    if (self.audioPlayer.isPlaying) {
        self.isPlaying = nil;
        [_playPauseButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    } else {
        [_playPauseButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
}

//- (IBAction)playPauseButtonTapped:(UIButton *)sender
//{
//    if (self.audioPlayer.isPlaying) {
//        [self.audioPlayer setIsPlaying:NO callback:^(NSError *error) {
//        }];
//        self.isPlaying = nil;
//        [self.playPauseButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
//    } else if (!self.isPlaying) {
//        [self.audioPlayer setIsPlaying:YES callback:^(NSError *error) {
//        }];
//        [self.playPauseButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
//        self.isPlaying = YES;
//    }
//}


- (IBAction)nextButtonTapped:(id)sender
{
}

- (IBAction)previousButtonTapped:(id)sender
{
    
}

@end
