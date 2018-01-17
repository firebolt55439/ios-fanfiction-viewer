//
//  StoryView.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/21/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "StoryView.h"
#import "MarkupParser.h"
#import "AppDelegate.h"
#import "DetailViewController.h"
@import CoreData;

@implementation StoryView {
    NSTextStorage* textStorage; // text storage for the story
    NSLayoutManager* layoutManager; // layout manager utilizing the text storage
    UIActivityIndicatorView* spinningBar; // indeterminate spinning loading bar
    FFStoryInfo* currentStoryInfo; // the current story info
}

@synthesize previousPage;

- (void)displayLoadingIndicator {
    if(spinningBar) return;
    spinningBar = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinningBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    CGRect frame = spinningBar.frame;
    frame.size = CGSizeMake(40.0, 40.0);
    frame.origin.x = self.frame.size.width / 2 - frame.size.width / 2;
    frame.origin.y = self.frame.size.height / 2 - frame.size.height / 2;
    spinningBar.frame = frame;
    [spinningBar setHidden:NO];
    [self addSubview:spinningBar];
    [self bringSubviewToFront:spinningBar];
    [spinningBar startAnimating];
    //[spinningBar bringSubviewToFront:self];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)stopLoadingIndicator {
    [spinningBar stopAnimating];
    [spinningBar removeFromSuperview];
    spinningBar = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)setStoryText:(NSString*)text forId:(NSString*)story_id withTitle:(NSString*)title {
    // Save the story ID and title.
    self.storyId = story_id;
    self.storyTitle = title;
    
    // Initialize any needed variables.
    previousPage = 0;
    self.delegate = self;
    
    // Strip any newlines contained in the HTML markup.
    text = [text stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    text = [text stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    /*
     NSLog(@"Occurence: %ld", [text rangeOfString:@"\n"].location);
     NSLog(@"Text: %@", [text substringToIndex:1000]);
     for(NSUInteger i = [text rangeOfString:@"Anakin, and a"].location; i < [text rangeOfString:@"Yoda,"].location; i++){
     char c = [text characterAtIndex:i];
     NSLog(@"Char: |%c| / |%d|", c, (int)c);
     }
     */
    
    // Parse the story and build an attributed string from the HTML markup.
    MarkupParser* p = [[MarkupParser alloc] init];
    NSAttributedString* attString = [p attrStringFromMarkup:text];
    
    // Add the title and author information to the attributed string.
    FFStoryInfo* info = [_manager getInfoForStoryWithID:story_id fromSource:FFNet];
    if(!info){
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"No network!" message:@"Could not download story." preferredStyle:UIAlertControllerStyleAlert];
        [_detailController presentViewController:alert animated:YES completion:nil];
        return;
    }
    currentStoryInfo = info;
    NSString* markup = [NSString stringWithFormat:@"<center><font face=\"Copperplate\"><h1>%@</h1></font><br />By: <i>%s</i></center><br /><center>---</center><br /><br />", title, info->author];
    NSMutableAttributedString* infoAttString = [[p attrStringFromMarkup:markup] mutableCopy];
    [infoAttString appendAttributedString:attString];
    attString = infoAttString;
    
    // Import the content into a text storage object.
    textStorage = [[NSTextStorage alloc] initWithAttributedString:attString];
    
    // Create the layout manager.
    layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    
    // Layout the content.
    if(spinningBar){
        [self stopLoadingIndicator];
    }
    [self layoutTextContainers];
    
    // Set up this scroll view.
    self.userInteractionEnabled = YES;
}

- (void)layoutTextContainers {
    // Remove any lingering subviews.
    for(UIView* subview in self.subviews){
        [subview removeFromSuperview];
    }
    
    // Initialize loop variables and perform layout loop.
    NSUInteger lastRenderedGlyph = 0;
    CGFloat currentXOffset = 0;
    const NSUInteger NUMBER_OF_COLUMNS = ([UIScreen mainScreen].nativeBounds.size.width > 700 ? 2 : 1);
    while(lastRenderedGlyph < layoutManager.numberOfGlyphs) {
        // Compute the frame sizes.
        CGRect textViewFrame = CGRectMake(currentXOffset, 10,
                                          CGRectGetWidth(self.bounds) / NUMBER_OF_COLUMNS,
                                          CGRectGetHeight(self.bounds) - 20);
        CGSize columnSize = CGSizeMake(CGRectGetWidth(textViewFrame) - 20,
                                       CGRectGetHeight(textViewFrame) - 10);
        
        // Initialize the container with the specified frame sizes.
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:columnSize];
        [layoutManager addTextContainer:textContainer];
        
        // And a text view to render it.
        UITextView *textView = [[UITextView alloc] initWithFrame:textViewFrame
                                                   textContainer:textContainer];
        textView.editable = YES;
        textView.selectable = YES;
        textView.userInteractionEnabled = YES;
        textView.allowsEditingTextAttributes = YES;
        [textView setTag:lastRenderedGlyph];
        //NSLog(@"%f / %f", textView.contentSize.height, textView.contentSize.width);
        //[textView flashScrollIndicators];
        [self addSubview:textView];
        textView.scrollEnabled = NO;
        
        // Increase the current offset.
        currentXOffset += CGRectGetWidth(textViewFrame);
        
        // Find the index of the glyph we've just rendered.
        lastRenderedGlyph = NSMaxRange([layoutManager glyphRangeForTextContainer:textContainer]);
    }
    
    // Update the scrollView size.
    CGSize contentSize = CGSizeMake(currentXOffset, CGRectGetHeight(self.bounds));
    self.contentSize = contentSize;
    
    // Enable paging.
    self.pagingEnabled = YES;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    if(recognizer.numberOfTouches > 1) return;
    NSLog(@"Single tap recorded.");
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
        NSLog(@"Right - width: %f, content size: %f", (self.frame.size.width * (newPage + 1)), self.contentSize.width);
        if((self.frame.size.width * (newPage + 1)) < self.contentSize.width){
            ++newPage;
        } else {
            NSLog(@"Over the edge.");
            // Next chapter, if possible.
            DetailViewController* controller = (DetailViewController*)_detailController;
            [controller setChapter:(controller.chapter + 1)];
            [controller setInitialPage:0];
            [controller dispatchConfigure];
        }
    } else {
        /*
        // Pass on tap to underlying UITextView.
        dispatch_async(dispatch_get_main_queue(), ^{
            UITextView* textView = (UITextView *)recognizer.view;
            NSLayoutManager *textLayoutManager = textView.layoutManager;
            CGPoint location = [recognizer locationInView:textView];
            location.x -= textView.textContainerInset.left;
            location.y -= textView.textContainerInset.top;
            NSUInteger characterIndex;
            characterIndex = [textLayoutManager characterIndexForPoint:location inTextContainer:textView.textContainer fractionOfDistanceBetweenInsertionPoints:NULL];
            if (characterIndex < textView.textStorage.length) {
                NSRange range;
                //id value = [textView.attributedText attribute:@"myCustomTag" atIndex:characterIndex effectiveRange:&range];
                NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:@[ NSLinguisticTagSchemeTokenType ] options:kNilOptions];
                tagger.string = [textView.attributedText string];
                NSString *tag = [tagger tagAtIndex:characterIndex scheme:NSLinguisticTagSchemeTokenType tokenRange:&range sentenceRange:nil];
                if([tag isEqualToString:NSLinguisticTagWord]){
                    [textView select:self];
                    [textView setSelectedRange:range];
                }
                // Handle as required...
                //NSLog(@"%@, %d, %d", value, range.location, range.length);
            }
        });
         */
    }
    if(didScroll){
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setContentOffset:CGPointMake(weakSelf.frame.size.width * newPage, 0.0f) animated:YES];
        });
    }
    //NSLog(@"Single tap recorded at (%f, %f) out of %.0fx%.0f.", location.x, location.y, size.width, size.height);
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    if(recognizer.numberOfTouches > 2) return;
    NSLog(@"Double tap recorded.");
    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    CGSize size = recognizer.view.bounds.size;
    double x = location.x;
    if(x <= (0.2 * size.width) || x >= (0.8 * size.width)) return;
    
    // Prompt whether to save author as a favorite author or to save story as a favorite story.
    __block UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Favorite" message:@"What do you want to favorite: this story or its author?" preferredStyle:UIAlertControllerStyleActionSheet];
    __block __weak NSString* currentStoryId = _storyId;
    __block FFStoryInfo* storyInfo = currentStoryInfo;
    if(!storyInfo || !currentStoryId) return; // we need the information to proceed
    UIAlertAction* saveStory = [UIAlertAction actionWithTitle:@"Story" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Saving story to favorites");
        // TODO
        [alert dismissViewControllerAnimated:YES completion:nil];
        abort(); // Not implemented yet
    }];
    UIAlertAction* saveAuthor = [UIAlertAction actionWithTitle:@"Author" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Saving author to favorites");
        
        // Save the author.
        NSManagedObjectContext* context = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
        NSFetchRequest* req = [[NSFetchRequest alloc] initWithEntityName:@"FavAuthor"];
        NSMutableArray* reqArr = [[context executeFetchRequest:req error:nil] mutableCopy];
        NSLog(@"Saved Authors: %@", reqArr);
        NSString* curAuthorId = [NSString stringWithFormat:@"%s", storyInfo->authorId];
        if(reqArr.count > 0){
            // Already have some authors saved.
            for(NSManagedObject* obj in reqArr){
                NSString* name = [obj valueForKey:@"authorId"];
                if([name isEqualToString:curAuthorId]){
                    return; // already a favorite author
                }
            }
        }
        NSManagedObject* author = [NSEntityDescription insertNewObjectForEntityForName:@"FavAuthor" inManagedObjectContext:context];
        [author setValue:curAuthorId forKey:@"authorId"];
        [author setValue:[NSString stringWithFormat:@"%s", storyInfo->author] forKey:@"name"];
        if(![context save:nil]) NSLog(@"Error saving!");
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:saveStory];
    [alert addAction:saveAuthor];
    [alert addAction:cancel];
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [(DetailViewController*)weakSelf.detailController presentViewController:alert animated:YES completion:nil];
    });
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"TOUCH BEGAN!");
    //[self.nextResponder touchesBegan:touches withEvent:event];
}

#pragma mark - UIScrollViewDelegate

// Handle page change.
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.frame.size.width;
    float fractionalPage = self.contentOffset.x / pageWidth;
    __block NSInteger page = lround(fractionalPage);
    if (previousPage != page) {
        NSLog(@"Now on page %ld from %ld", (long)page, (unsigned long)previousPage);
        
        // Save current page number.
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSManagedObjectContext* context = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
            NSFetchRequest* req = [[NSFetchRequest alloc] initWithEntityName:@"Story"];
            NSMutableArray* reqArr = [[context executeFetchRequest:req error:nil] mutableCopy];
            bool found = false;
            NSManagedObject* foundObj;
            NSString* ourId = [NSString stringWithFormat:@"%@ (%@)", self.storyTitle, self.storyId];
            //NSLog(@"# Found: %ld for our ID: %@", reqArr.count, ourId);
            if(reqArr.count > 0){
                for(NSManagedObject* obj in reqArr){
                    //NSLog(@"Saw id: %@", (NSString*)[obj valueForKey:@"id"]);
                    if([(NSString*)[obj valueForKey:@"id"] isEqualToString:ourId]){
                        foundObj = obj;
                        found = true;
                        break;
                    }
                }
            }
            if(found){
                //NSLog(@"Saving page %ld to object: %@", page, foundObj);
                [foundObj setValue:[NSNumber numberWithLong:page] forKey:@"lastPage"];
            }
            if(![context save:nil]) NSLog(@"Error saving!");
        });
        
        // Finally, update previous page.
        previousPage = page;
    }
}

@end
