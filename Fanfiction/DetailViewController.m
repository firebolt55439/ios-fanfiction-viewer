//
//  DetailViewController.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/17/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import <CoreText/CoreText.h>
#import "MarkupParser.h"
@import CoreData;

@interface DetailViewController ()

@end

@implementation DetailViewController

@synthesize chapter;
@synthesize initialPage;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }
}

- (IBAction)nextChapterButtonPressed:(id)sender {
    ++chapter;
    initialPage = 0;
    [self dispatchConfigure];
}

- (IBAction)prevChapterButtonPressed:(id)sender {
    if(chapter > 1){
        --chapter;
        initialPage = 0;
        [self dispatchConfigure];
    }
}

#pragma mark - View Configuration and Setup

- (void)configureView {
    // Update the user interface for the detail item.
    if (!self.detailItem){
        return;
    }
    
    // Initialize any necessary variables.
    __weak __typeof(self) weakSelf = self;
    __block NSUInteger weakChapter = chapter, weakPage = initialPage;
    
    // Display progress.
    dispatch_sync(dispatch_get_main_queue(), ^{
        [weakSelf.view bringSubviewToFront:weakSelf.progressView];
        [weakSelf.progressView setHidden:NO];
        if(weakSelf.detailItem){
            [weakSelf.storyView displayLoadingIndicator];
        }
    });
    
    // Extract the ID from the story name.
    NSString* item = (NSString*)self.detailItem;
    size_t pos = item.length - 1;
    while([item characterAtIndex:pos] != '(') --pos;
    __block NSString* plainTitle = [item substringToIndex:(pos - 1)];
    NSRange r;
    r.location = pos + 1;
    r.length = item.length - pos - 2;
    NSString* story_id = [item substringWithRange:r];
    
    // Download the story.
    NSLog(@"Unhidden");
    __block NSString* story;
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSLog(@"Downloading story with id %@...", story_id);
        story = [weakSelf.manager downloadStoryWithID:story_id fromSource:FFNet chapter:weakChapter progress:weakSelf.progressView];
        NSLog(@"Got: %ld chars", story.length);
    });
    //NSLog(@"Screen: %f / %f", [UIScreen mainScreen].nativeBounds.size.width, [UIScreen mainScreen].nativeBounds.size.height);
    //NSLog(@"Scale: %f / %f", [UIScreen mainScreen].scale, [UIScreen mainScreen].nativeScale);
    dispatch_sync(dispatch_get_main_queue(), ^{
        [weakSelf.progressView setHidden:YES];
    });
    
    // Display the story and update the title.
    if(story.length == 0){
        if(chapter > 1) --chapter; // it is likely that we have gone too far in terms of chapters
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf.storyView stopLoadingIndicator];
        });
        return;
    }
    //NSLog(@"Super: %f", self.view.bounds.size.width);
    dispatch_async(dispatch_get_main_queue(), ^{
        // Display the story and set the navbar title accordingly.
        [weakSelf.storyView setStoryText:story forId:story_id withTitle:plainTitle];
        [weakSelf.navbar setTitle:[NSString stringWithFormat:@"Chapter %ld", weakChapter]];
        
        // Scroll to initial page.
        NSLog(@"Weak page: %ld", weakPage);
        [weakSelf.storyView setContentOffset:CGPointMake(weakSelf.storyView.frame.size.width * weakPage, 0.0f) animated:YES];
        /*
        [weakSelf.textView setAttString:attString];
        [weakSelf.textView buildFrames];
        
        // Set page to initial page.
        [weakSelf.textView setContentOffset:CGPointMake(weakSelf.textView.frame.size.width * weakPage, 0.0f) animated:YES];
         */
        
        // Save where we are.
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSManagedObjectContext* context = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
            NSFetchRequest* req = [[NSFetchRequest alloc] initWithEntityName:@"Story"];
            NSMutableArray* reqArr = [[context executeFetchRequest:req error:nil] mutableCopy];
            bool found = false;
            NSManagedObject* foundObj;
            if(reqArr.count > 0){
                for(NSManagedObject* obj in reqArr){
                    if([(NSString*)[obj valueForKey:@"id"] isEqualToString:(NSString*)self.detailItem]){
                        foundObj = obj;
                        found = true;
                        break;
                    }
                }
            }
            if(!found){
                NSManagedObject* newStory = [NSEntityDescription insertNewObjectForEntityForName:@"Story" inManagedObjectContext:context];
                [newStory setValue:weakSelf.detailItem forKey:@"id"];
                [newStory setValue:[NSNumber numberWithLong:weakChapter] forKey:@"lastChapter"];
                [newStory setValue:[NSNumber numberWithLong:weakPage] forKey:@"lastPage"];
                [newStory setValue:[NSNumber numberWithInt:FFNet] forKey:@"source"]; // TODO
            } else {
                [foundObj setValue:[NSNumber numberWithLong:weakChapter] forKey:@"lastChapter"];
                [foundObj setValue:[NSNumber numberWithLong:weakPage] forKey:@"lastPage"];
            }
            if(![context save:nil]) NSLog(@"Error saving!");
        });
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    chapter = 1; // read the first chapter initially
    initialPage = 0; // start from the first page
    _textView.detailController = self;
    [_textView setStoryId:self.detailItem];
    _progressView = [[ProgressView alloc] initWithFrame:_progressView.frame];
    if(_detailItem){
        [_storyView displayLoadingIndicator];
    }
    [_storyView setDetailController:self];
    [_storyView setManager:_manager];
    
    // Check if we have read this before and left off anywhere.
    NSManagedObjectContext* context = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest* req = [[NSFetchRequest alloc] initWithEntityName:@"Story"];
    NSMutableArray* reqArr = [[context executeFetchRequest:req error:nil] mutableCopy];
    //NSLog(@"Saved: %@", reqArr);
    if(reqArr.count > 0){
        for(NSManagedObject* obj in reqArr){
            if([(NSString*)[obj valueForKey:@"id"] isEqualToString:(NSString*)self.detailItem]){
                chapter = [(NSNumber*)[obj valueForKey:@"lastChapter"] longValue];
                initialPage = [(NSNumber*)[obj valueForKey:@"lastPage"] longValue];
                break;
            }
        }
    }
    
    // Update the title and configure the navigation controller/navbar.
    [_navbar setTitle:[NSString stringWithFormat:@"Chapter %ld", (unsigned long)chapter]];
    if(!_detailItem){
        [_navbar setTitle:@"(No Story Selected)"];
    }
    //self.navigationController.hidesBarsOnTap = YES;
    //self.navigationController.hidesBarsOnSwipe = YES;
    
    // Add a gesture recognizer for quick page navigation that listens for single taps.
    UITapGestureRecognizer* singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:_storyView action:@selector(handleSingleTap:)];
    singleFingerTap.delegate = self;
    singleFingerTap.cancelsTouchesInView = NO;
    singleFingerTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleFingerTap];
    
    // Add a gesture recognizer for favoriting either authors or stories activated on double-tap.
    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:_storyView action:@selector(handleDoubleTap:)];
    doubleTap.delegate = self;
    doubleTap.cancelsTouchesInView = NO;
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)dispatchConfigure {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [weakSelf configureView];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    // Dispatch an asynchronous call on the main thread to configureView with a delay.
    [self dispatchConfigure];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
