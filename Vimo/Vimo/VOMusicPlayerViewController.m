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

@property (nonatomic) UIImage *playImage;
@property (nonatomic) UIImage *pauseImage;

@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL isRunning;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;


@end

@implementation VOMusicPlayerViewController

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Player";
    
    self.isPlaying = NO;
}

#pragma mark - Music Player Implementation

- (IBAction)playPauseButtonTapped:(UIButton *)sender
{
    if (self.isPlaying) {
        self.isPlaying = nil;
        [self.playPauseButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    } else if (!self.isPlaying) {
        [self.playPauseButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        self.isPlaying = YES;
    }
}

- (IBAction)nextButtonTapped:(id)sender
{
}

- (IBAction)previousButtonTapped:(id)sender
{
    
}

@end
