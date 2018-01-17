//
//  StoryView.h
//  Fanfiction
//
//  Created by Sumer Kohli on 12/21/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FFManager.h"

@interface StoryView : UIScrollView <UIScrollViewDelegate>

@property (weak, nonatomic) id detailController; // the associated detail controller
@property (retain, nonatomic) NSString* storyTitle; // the title of the story we are displaying
@property (retain, nonatomic) NSString* storyId; // the ID of the story we are displaying
@property (assign, readwrite) NSUInteger previousPage; // previous page for paging purposes
@property (weak, nonatomic) FFManager* manager;

- (void)displayLoadingIndicator;
- (void)stopLoadingIndicator;
- (void)setStoryText:(NSString*)text forId:(NSString*)story_id withTitle:(NSString*)title; // set the story text and layout the text container
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer;
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer;

@end
