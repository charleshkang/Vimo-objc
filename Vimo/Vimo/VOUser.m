//
//  VOUser.m
//  Vimo
//
//  Created by Charles Kang on 2/25/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "VOUser.h"

@implementation VOUser

static VOUser *user = nil;

+ (VOUser *)user
{
    if (!user) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            user = [self new];
        });
    }
    return user;
}

- (void)handle:(SPTSession *)session
{
    if (session) {
        _spotifySession = session;
    }
    [SPTRequest userInformationForUserInSession:session callback:^(NSError *error, id object) {
        if (!error) {
            self.spotifyUser = (SPTUser *)object;
            [self.playlistsVC reloadWithPlaylists];

        } else {
            NSLog(@"Error: %@", error);
        }
    }];
}

@end
