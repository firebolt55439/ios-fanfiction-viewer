//
//  CTColumnView.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/18/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "CTColumnView.h"

@implementation CTColumnView

-(void)setCTFrame:(id)f {
    ctFrame = f;
}

-(void)drawRect:(CGRect)rect {
    // Get the context.
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Flip the coordinate system.
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // Draw the frame in the context.
    CTFrameDraw((CTFrameRef)ctFrame, context);
}

@end