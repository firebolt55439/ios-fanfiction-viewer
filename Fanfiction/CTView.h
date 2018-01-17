//
//  CTView.h
//  Fanfiction
//
//  Created by Sumer Kohli on 12/18/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "CTColumnView.h"

@interface CTView : UIScrollView<UIScrollViewDelegate> {
    NSMutableArray* frames;
    float frameXOffset;
    float frameYOffset;
}

@property (weak, nonatomic) id detailController; // detail view controller for this text view
@property (weak, nonatomic) NSString* storyId; // story ID currently being displayed
@property (retain, nonatomic) NSAttributedString* attString;
@property (retain, nonatomic) NSMutableArray* frames;

- (void)buildFrames;
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer;

@end
