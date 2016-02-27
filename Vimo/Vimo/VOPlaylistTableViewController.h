//
//  VOPlaylistTableViewController.h
//  Vimo
//
//  Created by Charles Kang on 2/26/16.
//  Copyright © 2016 Charles Kang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VOPlaylistTableViewController : UITableViewController

@property (nonatomic) VOPlaylistTableViewController *playlistsVC;
@property (nonatomic) NSMutableArray *playlists;

-(void)reloadWithPlaylists;

@end
