//
//  ProgressView.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/18/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "ProgressView.h"

@implementation ProgressView

- (void)createLabels {
    // Set up the progress label.
    progressLabel = [[UILabel alloc] init];
    progressLabel.textColor = [UIColor whiteColor];
    progressLabel.textAlignment = NSTextAlignmentCenter;
    progressLabel.text = @"0 %";
    progressLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:40.0f];
    [progressLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:progressLabel];
    
    // Add constraints.
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:progressLabel attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:progressLabel attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    
    // Set up download progress label.
    sizeProgressLabel = [[UILabel alloc] init];
    sizeProgressLabel.textColor = [UIColor whiteColor];
    sizeProgressLabel.textAlignment = NSTextAlignmentCenter;
    sizeProgressLabel.text = @"0.0 MB / 0.0 MB";
    sizeProgressLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size: 10.0];
    [sizeProgressLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:sizeProgressLabel];
    
    // Add constraints.
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:sizeProgressLabel attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:sizeProgressLabel attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
}

- (void)createProgressLayer {
    // Initialize constants.
    const double startAngle = M_PI_2, endAngle = (M_PI * 2.0f + M_PI_2);
    const CGPoint centerPoint = CGPointMake(CGRectGetWidth(self.frame) / 2, CGRectGetHeight(self.frame) / 2);
    
    // Set up progress layer.
    progressLayer = [[CAShapeLayer alloc] init];
    progressLayer.path = [UIBezierPath bezierPathWithArcCenter:centerPoint radius:(CGRectGetWidth(self.frame) / 2) startAngle:startAngle endAngle:endAngle clockwise:true].CGPath;
    progressLayer.backgroundColor = [UIColor clearColor].CGColor;
    progressLayer.fillColor = nil;
    progressLayer.strokeColor = [UIColor whiteColor].CGColor;
    progressLayer.lineWidth = 4.0f;
    progressLayer.strokeStart = 0.0f;
    progressLayer.strokeEnd = 0.0f;
    [self.layer addSublayer:progressLayer];
    
    // Set up dashed layer.
    dashedLayer = [[CAShapeLayer alloc] init];
    dashedLayer.strokeColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    dashedLayer.fillColor = nil;
    dashedLayer.lineDashPattern = @[@2, @4];
    dashedLayer.lineJoin = @"round";
    dashedLayer.lineWidth = 2.0f;
    dashedLayer.path = progressLayer.path;
    [self.layer insertSublayer:dashedLayer below:progressLayer];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        [self setUpView];
    }
    return self;
}

- (void)setUpView {
    //[self createLabels];
    //[self createProgressLayer];
    //[self animateProgressViewToProgress:0.00];
    NSLog(@"LOADED!!!");
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.center = self.center;
    activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [activityView startAnimating];
    [self addSubview:activityView];
}

- (void)animateProgressViewToProgress:(double)progress {
    NSLog(@"Animating for progress: %f", progress);
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = [NSNumber numberWithFloat:progressLayer.strokeEnd];
    animation.toValue = [NSNumber numberWithFloat:progress];
    animation.duration = 0.2f;
    animation.fillMode = kCAFillModeForwards;
    progressLayer.strokeEnd = progress;
    [progressLayer addAnimation:animation forKey:@"animation"];
}

- (void)updateProgressViewLabelWithProgress:(double)percent {
    NSLog(@"Animating for progress: %f", percent);
    progressLabel.text = [NSString stringWithFormat:@"%.0f %@", percent, @"%"];
}

- (double)convertToMB:(double)size {
    return (size / 1024.0f) / 1024.0f;
}

- (void)updateProgressViewWith:(double)totalSent totalFileSize:(double)totalFileSize {
    sizeProgressLabel.text = [NSString stringWithFormat:@"%.1f MB / %.1f MB", [self convertToMB:totalSent], [self convertToMB:totalFileSize]];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
