//
//  SplashScreenViewController.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/17/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "SplashScreenViewController.h"
#import "MasterViewController.h"

@implementation SplashScreenViewController

- (IBAction)prepareForUnwind:(UIStoryboardSegue*)segue {
    //
}

- (void)viewDidLoad {
    // Initialize the data manager.
    _manager = [[FFManager alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    // Go back.
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        usleep(2e6);
        [weakSelf performSegueWithIdentifier:@"exitSegue" sender:weakSelf];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"exitSegue"]){
        ((MasterViewController*)segue.destinationViewController).manager = _manager;
    }
}

@end
