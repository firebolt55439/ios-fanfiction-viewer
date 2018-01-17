//
//  DetailViewController.h
//  Fanfiction
//
//  Created by Sumer Kohli on 12/17/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FFManager.h"
#import "CTView.h"
#import "StoryView.h"

@interface DetailViewController : UIViewController <UIGestureRecognizerDelegate> {
    //
}

@property (assign, readwrite) NSUInteger chapter;
@property (assign, readwrite) NSUInteger initialPage;
@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) FFManager* manager;
@property (weak, nonatomic) IBOutlet CTView *textView;
@property (weak, nonatomic) IBOutlet StoryView *storyView;
@property (strong, nonatomic) IBOutlet ProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextChapterButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *navbar;

- (void)dispatchConfigure;

@end

