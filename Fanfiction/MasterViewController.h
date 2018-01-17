//
//  MasterViewController.h
//  Fanfiction
//
//  Created by Sumer Kohli on 12/17/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplashScreenViewController.h"
#import "FFManager.h"
#import "MasterViewCellTableViewCell.h"
#import "BrowseViewController.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, retain, nonatomic) FFManager* manager;
@property (strong, retain, nonatomic) NSString* browsePathPrefix; // e.g. /crossovers/anime, /book, etc.
@property (strong, retain, nonatomic) NSMutableArray *categoryNames, *categoryStories; // stories, ind --> [stories]
@property (weak, nonatomic) IBOutlet UINavigationItem *navbar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString* storyToShowDirectly; // if not nil when viewWillAppear: called, then this story will be displayed

- (void)asyncPopulateStoryCellAt:(NSIndexPath*)path inView:(UITableView*)theTableView forId:(NSString*)sid initialCell:(MasterViewCellTableViewCell*)initialCell;

@end