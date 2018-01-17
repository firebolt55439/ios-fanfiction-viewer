//
//  CTView.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/18/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "AppDelegate.h"
#import "CTView.h"
#import "MarkupParser.h"
#import "DetailViewController.h"
@import CoreData;

@implementation CTView {
    int maxWidth, maxHeight; // guaranteed to be zero-initialized
    NSInteger previousPage; // zero-initialized
}

@synthesize attString;
@synthesize frames;

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

- (void)buildFrames {
    // Initialize frame offsets.
    frameXOffset = 20;
    frameYOffset = 20;
    
    // Adjust the frame and ensure that the width/height we are using is the same. //
    // Note: Retina scale can be off (usually by a factor of 2x, so using .nativeBounds corrects that).
    const int WIDTH = [UIScreen mainScreen].nativeBounds.size.width - 2 * frameXOffset;
    const int HEIGHT = self.bounds.size.height;
    
    // Clear out subviews and reset.
    for(UIView* view in self.subviews) [view removeFromSuperview];
    self.contentSize = CGSizeMake(0, 0);
    
    // Initialize any needed variables.
    self.pagingEnabled = YES;
    self.delegate = self;
    self.frames = [NSMutableArray array];
    
    // Create the path.
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect rct = self.bounds;
    rct.size = CGSizeMake(WIDTH, HEIGHT);
    CGRect textFrame = CGRectInset(rct, frameXOffset, frameYOffset);
    CGPathAddRect(path, NULL, textFrame );
    
    // Create the framesetter.
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    int textPos = 0; //3
    int columnIndex = 0;
    int totalWidth = 0;
    
    while (textPos < [attString length]) {
        // Compute the column offset location and the bounding rectangle dimensions.
        CGPoint colOffset = CGPointMake( (columnIndex+1)*frameXOffset + columnIndex*(textFrame.size.width/2 + 28), 20 );
        CGRect colRect = CGRectMake(0, 0 , textFrame.size.width/2 + 10, textFrame.size.height - 0.5 * frameYOffset);
        
        // Modify the path as necessary.
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, colRect);
        
        // Use the column path
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, NULL);
        CFRange frameRange = CTFrameGetVisibleStringRange(frame); //5
        
        // Create an empty column view
        CTColumnView* content = [[CTColumnView alloc] initWithFrame: CGRectMake(0, 0, textFrame.size.width, textFrame.size.height)];
        content.backgroundColor = [UIColor clearColor];
        content.frame = CGRectMake(colOffset.x, colOffset.y, colRect.size.width, colRect.size.height);
        totalWidth += colRect.size.width;
        
        // Set the column view contents and add it as subview
        [content setCTFrame:(__bridge id)frame];  //6
        [self.frames addObject: (__bridge id)frame];
        [self addSubview: content];
        
        // Prepare for next frame
        textPos += frameRange.length;
        
        // Clean up.
        CFRelease(path);
        columnIndex++;
    }
    
    // Set the total width of the scroll view.
    //int totalPages = (columnIndex + 1) / 2;
    NSLog(@"%f vs %f", self.bounds.size.width, textFrame.size.width);
    self.contentSize = CGSizeMake(totalWidth * 1.131f, self.bounds.size.height);
}

// Handle page change.
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.frame.size.width;
    float fractionalPage = self.contentOffset.x / pageWidth;
    __block NSInteger page = lround(fractionalPage);
    if (previousPage != page) {
        NSLog(@"Now on page %ld from %ld", page, previousPage);
        
        // Save current page number.
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSManagedObjectContext* context = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
            NSFetchRequest* req = [[NSFetchRequest alloc] initWithEntityName:@"Story"];
            NSMutableArray* reqArr = [[context executeFetchRequest:req error:nil] mutableCopy];
            bool found = false;
            NSManagedObject* foundObj;
            if(reqArr.count > 0){
                for(NSManagedObject* obj in reqArr){
                    if([(NSString*)[obj valueForKey:@"id"] isEqualToString:(NSString*)self.storyId]){
                        foundObj = obj;
                        found = true;
                        break;
                    }
                }
            }
            if(found){
                [foundObj setValue:[NSNumber numberWithLong:page] forKey:@"lastPage"];
            }
            if(![context save:nil]) NSLog(@"Error saving!");
        });
        
        // Finally, update previous page.
        previousPage = page;
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    CGSize size = recognizer.view.bounds.size;
    double x = location.x;
    __block CGRect frame;
    frame.origin.y = 0;
    bool didScroll = false;
    __weak __typeof(self) weakSelf = self;
    __block NSInteger newPage = previousPage;
    if(x <= (0.2 * size.width)){
        // Go left.
        didScroll = true;
        NSLog(@"Left");
        if(newPage > 0) --newPage;
    } else if(x >= (0.8 * size.width)){
        // Go right.
        didScroll = true;
        NSLog(@"Right");
        if((self.frame.size.width * (newPage + 1)) <= self.contentSize.width){
            ++newPage;
        } else {
            // Next chapter, if possible.
            DetailViewController* controller = (DetailViewController*)_detailController;
            [controller setChapter:(controller.chapter + 1)];
            [controller setInitialPage:0];
            [controller dispatchConfigure];
        }
    }
    if(didScroll){
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setContentOffset:CGPointMake(weakSelf.frame.size.width * newPage, 0.0f) animated:YES];
        });
    }
    //NSLog(@"Single tap recorded at (%f, %f) out of %.0fx%.0f.", location.x, location.y, size.width, size.height);
}

-(void)dealloc {
    self.attString = nil;
    self.frames = nil;
}

@end
