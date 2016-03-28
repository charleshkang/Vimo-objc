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

#import "Config.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface VOMusicPlayerViewController ()
<
SPTAudioStreamingDelegate
>

@property (nonatomic) SPTPlaylistSnapshot *currentPlaylist;
@property (nonatomic) NSMutableArray *trackURIs;
@property (nonatomic) SPTArtist *currentArtist;
@property (nonatomic) int currentSongIndex;

@property (nonatomic) UIImage *playImage;
@property (nonatomic) UIImage *pauseImage;

@property (weak,nonatomic) IBOutlet UIButton *playPauseButton;

@property (weak,nonatomic) IBOutlet UIImageView *coverView;
@property (weak,nonatomic) IBOutlet UILabel *titleLabel;
@property (weak,nonatomic) IBOutlet UILabel *artistLabel;

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
    [self navBarLogic];
    [self setupGestureRecognizer];
    [self setPlaylistWithPartialPlaylist:self.partialPlaylist];
}

#pragma mark - Spotify Player Methods

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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Spotify Message:"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:nil];
    [alertController addAction:ok];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didStartPlayingTrack:(NSURL *)trackUri
{
    self.currentSongIndex = self.audioPlayer.currentTrackIndex;
    [SPTTrack trackWithURI:trackUri session:self.session callback:^(NSError *error, SPTTrack *track) {
        self.currentTrack = track;
        
        self.titleLabel.text = self.currentTrack.name;
        SPTPartialArtist *artist = (SPTPartialArtist *)[self.currentTrack.artists objectAtIndex:0];
        self.artistLabel.text = artist.name;
        [self itemChangeCallBack];
        //        NSURL *coverArtURL = self.currentTrack.album.largestCover.imageURL;
        //
        //        if (coverArtURL) {
        //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //                NSError *error = nil;
        //                UIImage *image = nil;
        //                NSData *imageData = [NSData dataWithContentsOfURL:coverArtURL options:0 error:&error];
        //
        //                if (imageData != nil) {
        //                    image = [UIImage imageWithData:imageData];
        //                }
        //
        //                dispatch_async(dispatch_get_main_queue(), ^{
        //                    self.coverView.image = image;
        //                    if (image == nil) {
        //                        NSLog(@"Couldn't load cover image with error: %@", error);
        //                        return;
        //                    }
        //                });
        //            });
        //        }
    }
     ];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    [self itemChangeCallBack];
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
    [controller.spotifyPlayer setIsPlaying:!controller.spotifyPlayer.isPlaying callback:nil];
}

- (IBAction)backButtonTapped:(id)sender
{
    if (self.audioPlayer.isPlaying == YES) {
        [self.audioPlayer setIsPlaying:!self.audioPlayer.isPlaying callback:nil];
    }
    self.audioPlayer = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Swipe Gestures

- (void)setupGestureRecognizer
{
    
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc]
                                           initWithTarget: self
                                           action: @selector(handleSwipe:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]
                                            initWithTarget: self
                                            action: @selector(handleSwipe:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    
    
    [self.view addGestureRecognizer:leftSwipe];
    [self.view addGestureRecognizer:rightSwipe];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture
{
    switch (gesture.direction) {
            
        case UISwipeGestureRecognizerDirectionLeft:
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
                [self itemChangeCallBack];
                NSLog(@"skipped");
            }];
            break;
        }
        case UISwipeGestureRecognizerDirectionRight:
        {
            [self.audioPlayer
             skipPrevious:^(NSError *error) {
                 [self itemChangeCallBack];
                 NSLog(@"previous");
             }];
            
            break;
        }
        default:
        {
            break;
        }
    }
}

#pragma mark - Navigation Bar Logic

- (void)navBarLogic
{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

#pragma mark - Handle Callback

- (void)itemChangeCallBack
{
    [SPTTrack trackWithURI:self.audioPlayer.currentTrackURI session:self.session callback:^(NSError *error, id object) {
        SPTTrack *track = object;
        // Fetch the artwork from library
        [self.coverView sd_setImageWithURL:track.album.largestCover.imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        }];
    }
     ];}

@end
