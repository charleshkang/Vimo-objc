//
//  VOLoginVC.m
//  Vimo
//
//  Created by Charles Kang on 2/25/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "VOLoginVC.h"
#import "Config.h"
#import "VOUser.h"


#import <Spotify/Spotify.h>

@interface VOLoginVC ()
<
SPTAuthViewDelegate
>

@property (nonatomic) SPTAuthViewController *authViewController;
@property (nonatomic) VOUser *user;
@property (nonatomic) SPTArtist *genres;

@end

@implementation VOLoginVC

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (auth.hasTokenRefreshService) {
        [self renewAccessToken];
        return;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

#pragma mark - Spotify Login & Auth Implementation

- (IBAction)userLoggedInWithSpotify:(id)sender
{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.user) {
        [defaults setBool:YES forKey:@"hasLaunchedOnce"];
        [defaults setBool:YES forKey:@"UserLoggedIn"];
        VOPlaylistTableViewController *playlistVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"playlistsVC"];
        [self presentViewController:playlistVC animated:YES completion:nil];
        [defaults synchronize];
    }
    
    [self login];
    [self checkIfSessionIsValid];
}

- (void)checkIfSessionIsValid {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (auth.session == nil) {
        [self renewAccessToken];
    }
}

- (void)authenticationViewController:(SPTAuthViewController *)authenticationViewController didLoginWithSession:(SPTSession *)session
{
    VOPlaylistTableViewController *playlistsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"playlistsVC"];
    [self.navigationController pushViewController:playlistsVC animated:YES];
    
    [[VOUser user] handle:session];
    NSLog(@"Session Granted %@", session);
    
}

- (void)login
{
    self.authViewController = [SPTAuthViewController authenticationViewController];
    self.authViewController.delegate = self;
    self.authViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.authViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.definesPresentationContext = YES;
    
    [self presentViewController:self.authViewController animated:NO completion:nil];
}

- (void)renewAccessToken
{
    SPTAuth *auth = [SPTAuth defaultInstance];
    [auth renewSession:auth.session callback:^(NSError *error, SPTSession *session) {
        auth.session = session;
        if (error) {
            return;
        }
        
        [self.navigationController popToRootViewControllerAnimated:NO];
    }];
}

- (void)authenticationViewControllerDidCancelLogin:(SPTAuthViewController *)authenticationViewController
{
    [self login];
}

- (void)authenticationViewController:(SPTAuthViewController *)authenticationViewController didFailToLogin:(NSError *)error
{
    NSLog(@"Authentication Failed : %@", error);
}



@end
