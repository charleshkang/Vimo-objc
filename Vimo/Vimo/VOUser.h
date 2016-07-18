//
//  VOUser.h
//  Vimo
//
//  Created by Charles Kang on 2/25/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>
#import "VOPlaylistTableViewController.h"

@interface VOUser : NSObject

+ (VOUser *)user;
- (void)handle:(SPTSession *)session;

@property (nonatomic) SPTUser *spotifyUser;
@property (nonatomic) SPTSession *spotifySession;

@property (nonatomic) VOPlaylistTableViewController *playlistsVC;
@property(strong, nonatomic) SPTAudioStreamingController *spotifyPlayer;

@end