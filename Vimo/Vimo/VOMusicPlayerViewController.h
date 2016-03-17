//
//  VOMusicPlayerViewController.h
//  Vimo
//
//  Created by Charles Kang on 2/27/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface VOMusicPlayerViewController : UIViewController
<
SPTAudioStreamingDelegate,
SPTAudioStreamingPlaybackDelegate
>

@property (nonatomic) SPTPartialPlaylist *partialPlaylist;
@property (nonatomic) SPTSession *session;
@property (nonatomic) SPTTrack *currentTrack;

@property (nonatomic) SPTPlaylistList *playlist;

@property (nonatomic) SPTAudioStreamingController *audioPlayer;

- (void)setPlaylistWithPartialPlaylist:(SPTPartialPlaylist *)partialPlaylist;

@end
