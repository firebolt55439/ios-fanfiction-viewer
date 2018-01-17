//
//  AddSourceViewController.h
//  Fanfiction
//
//  Created by Sumer Kohli on 12/20/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FFManager.h"

@interface AddSourceViewController : UIViewController <UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) id masterController;
@property (weak, nonatomic) FFManager* manager;
@property (strong, retain, nonatomic) NSString* browsePathPrefix;
@property (strong, nonatomic) UISearchController* searchController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
