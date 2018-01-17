//
//  ProgressView.h
//  Fanfiction
//
//  Created by Sumer Kohli on 12/18/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressView : UIView {
    CAShapeLayer* progressLayer;
    UILabel* progressLabel;
    UILabel* sizeProgressLabel;
    CAShapeLayer* dashedLayer;
}

- (void)animateProgressViewToProgress:(double)progress;
- (void)updateProgressViewLabelWithProgress:(double)percent;
- (void)updateProgressViewWith:(double)totalSent totalFileSize:(double)totalFileSize;

@end
