//
//  VOSpotifyHelper.m
//  Vimo
//
//  Created by Charles Kang on 3/3/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "VOSpotifyHelper.h"
#import "VOMusicPlayerViewController.h"
#import "VOKeys.h"
#import "AppDelegate.h"

#import <Spotify/Spotify.h>

// Spotify Defaults: put this in app configuration
static NSString * const kSpotifyClientId = @"d5b5e89f88e146bbbeb0ad1375934f62";
static NSString * const kSpotifyCallbackURL = @"vimo://";
static NSString * const kSpotifySwapURL = @"https://vimo.herokuapp.com/swap";
static NSString * const  kSpotifyTokenRefreshServiceURL = @"https://vimo.herokuapp.com/refresh";

NSString * const kSpotifyDefaultSessionKey = @"SpotifySession";

@interface VOSpotifyHelper ()
<
SPTAudioStreamingDelegate,
SPTAudioStreamingPlaybackDelegate
>

@property (nonatomic) SPTSession *session;
@property (nonatomic) SPTAudioStreamingController *streamingPlayer;
@property (nonatomic) SPTPlaylistSnapshot *currentPlaylist;
@property (nonatomic) SPTTrack *nowPlayingTrack;


@property (nonatomic) NSMutableArray *tracks;
@property (nonatomic) NSMutableArray *starredTracks;
@property (nonatomic) NSMutableArray *savedTracks;
@property (nonatomic) NSMutableArray *playlists;
@property (nonatomic) NSArray *partialTracks;
@property (nonatomic) NSArray *partialPlaylists;

@property (nonatomic) NSInteger startingPlaylistIndex;

@property (nonatomic) dispatch_queue_t taskReadQueue;



@end

@implementation VOSpotifyHelper

@synthesize session;

#pragma mark - Singleton Methods

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static VOSpotifyHelper *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[VOSpotifyHelper alloc] init];
    });
    return shared;
}

- (void)initSpotify
{
    [SPTAuth defaultInstance].clientID = @kClientId;
    [SPTAuth defaultInstance].requestedScopes = [self getAccessTokenScopes];
    [SPTAuth defaultInstance].redirectURL = [NSURL URLWithString:kSpotifyCallbackURL];
    [SPTAuth defaultInstance].tokenRefreshURL = [NSURL URLWithString:kSpotifyTokenRefreshServiceURL];
    [SPTAuth defaultInstance].tokenSwapURL = [NSURL URLWithString:kSpotifySwapURL];
    [SPTAuth defaultInstance].sessionUserDefaultsKey = kSpotifyDefaultSessionKey;
    if(self.streamingPlayer == nil) { // initialize the Streaming Player
        
        self.streamingPlayer = [[SPTAudioStreamingController alloc] initWithClientId:kSpotifyClientId];
        [self.streamingPlayer setDelegate:self];
        [self.streamingPlayer setPlaybackDelegate:self];
        [self.streamingPlayer setTargetBitrate:SPTBitrateHigh callback:^(NSError *error) {
            if(error) {
            }
        }];
    }
}

- (NSArray*)getAccessTokenScopes
{
    return @[
             // Streaming
             SPTAuthStreamingScope,
             
             // Playlists
             SPTAuthPlaylistReadPrivateScope,
             
             // User Playlists
             SPTAuthPlaylistReadPrivateScope
             
             ];
    
}


@end
