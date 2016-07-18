//
//  AppDelegate.m
//  Vimo
//
//  Created by Charles Kang on 2/25/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "AppDelegate.h"
#import "Config.h"
#import "VOLoginVC.h"
#import "VOUser.h"
#import "VOPlaylistTableViewController.h"

#import <Spotify/Spotify.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Spotify Authorization Initializers
    SPTAuth *auth = [SPTAuth defaultInstance];
    auth.clientID = @kClientId;
    auth.redirectURL = [NSURL URLWithString:@kCallbackURL];
    auth.requestedScopes = @[SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope,
                             SPTAuthUserReadPrivateScope, SPTAuthUserLibraryReadScope];
    
#ifdef kTokenSwapServiceURL
    auth.tokenSwapURL = [NSURL URLWithString:@kTokenSwapServiceURL];
#endif
#ifdef kTokenRefreshServiceURL
    auth.tokenRefreshURL = [NSURL URLWithString:@kTokenRefreshServiceURL];
#endif
    auth.sessionUserDefaultsKey = @kSessionUserDefaultsKey;
    
    VOLoginVC *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"loginVC"];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:loginVC];
    
    if (auth.session == nil || ![auth.session isValid]) {
        [navigationController pushViewController:[VOLoginVC new] animated:NO];
    } else {
        [[VOUser user] handle:auth.session];
    }
    
    return YES;
}

@end