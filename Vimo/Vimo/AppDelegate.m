//
//  AppDelegate.m
//  Vimo
//
//  Created by Charles Kang on 2/25/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "AppDelegate.h"
#import "VOKeys.h"
#import "VOLoginVC.h"
#import "VOUser.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults boolForKey:@"hasLaunchedOnce"]) {
        VOLoginVC *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"loginViewController"];
        UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:loginVC];
        self.window.rootViewController = navigationController;
    } else if ([defaults boolForKey:@"hasLaunchedOnce"] && [defaults boolForKey:@"UserLoggedIn"]) {
        VOPlaylistTableViewController *playlistsVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"playlistsVC"];
        
        self.window.rootViewController = playlistsVC;
    }
    
    VOPlaylistTableViewController *playlistSelectionVC = [VOPlaylistTableViewController new];
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:playlistSelectionVC];

    
    // Spotify Authorization Initializers
    SPTAuth *auth = [SPTAuth defaultInstance];
    auth.clientID = @kClientId;
    
    auth.redirectURL = [NSURL URLWithString:@kCallbackURL];
    
    auth.requestedScopes = @[SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope,
                              SPTAuthUserLibraryReadScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthUserLibraryModifyScope];
    
    
#ifdef kTokenSwapServiceURL
    auth.tokenSwapURL = [NSURL URLWithString:@kTokenSwapServiceURL];
#endif
#ifdef kTokenRefreshServiceURL
    auth.tokenRefreshURL = [NSURL URLWithString:@kTokenRefreshServiceURL];
#endif
    auth.sessionUserDefaultsKey = @kSessionUserDefaultsKey;
    NSLog(@"Session: %@", auth.sessionUserDefaultsKey);
    
    if(auth.session == nil || ![auth.session isValid]) {
        [navVC pushViewController:[VOLoginVC new] animated:NO];
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
