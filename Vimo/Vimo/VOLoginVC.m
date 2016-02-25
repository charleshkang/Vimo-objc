//
//  VOLoginVC.m
//  Vimo
//
//  Created by Charles Kang on 2/25/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import "VOLoginVC.h"
#import "VOKeys.h"
#import "VOUser.h"

#import <Spotify/Spotify.h>

@interface VOLoginVC ()
<
SPTAuthViewDelegate
>

@property (nonatomic) SPTAuthViewController *authViewController;
@property (nonatomic) VOUser *user;

@end

@implementation VOLoginVC

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (auth.hasTokenRefreshService) {
        [self renewAccessToken];
        return;
    }
}

#pragma mark - Spotify Login & Auth Implementation

- (IBAction)userLoggedInWithSpotify:(id)sender
{
    
    //    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //    if (self.user) {
    //        [defaults setBool:YES forKey:@"hasLaunchedOnce"];
    //        [defaults setBool:YES forKey:@"UserLoggedIn"];
    //        [defaults synchronize];
    //    }
    
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
        
        //        [self.navigationController popToRootViewControllerAnimated:NO];
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
