//
//  BrowseViewController.h
//  Fanfiction
//
//  Created by Sumer Kohli on 12/23/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FFManager.h"

@interface BrowseViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) id masterController;
@property (weak, nonatomic) FFManager* manager;
@property (assign, readwrite) FFSource source;
@property (weak, nonatomic) IBOutlet UITextField *categoryTextField;
@property (weak, nonatomic) IBOutlet UITableView *titlesTable;

@end
