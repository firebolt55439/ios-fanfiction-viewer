//
//  MasterViewController.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/17/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "DetailViewController.h"
#import "FFManager.h"
#import "MarkupParser.h"
#import "AddSourceViewController.h"
@import CoreData;

@interface MasterViewController () {
    NSMutableDictionary* authorImageCache; // author image cache
    UIImage* placeholderAuthorImage; // placeholder author image
    UIActivityIndicatorView* spinningBar; // loading bar
}

//@property NSMutableArray *objects;

@end

@implementation MasterViewController {
    NSMutableArray* recentStories; // array of titles
}

@synthesize categoryNames;
@synthesize categoryStories;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // Set up the browse button.
    UIBarButtonItem* browseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(browseCategories:)];
    self.navigationItem.leftBarButtonItem = browseButton;
    
    // Configure the table view.
    [self.tableView registerClass:[MasterViewCellTableViewCell class] forCellReuseIdentifier:@"MasterViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MasterViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"MasterViewCell"];
    self.tableView.estimatedRowHeight = self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.rowHeight = 180.0f;
    [self.tableView setNeedsLayout];
    [self.tableView layoutIfNeeded];
    
    // Preload the placeholder image.
    placeholderAuthorImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://www.fanfiction.net/static/images/d_60_90.jpg"]]];
    
    // Set up the search button.
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    // Obtain and save a reference to the detail view controller.
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    // Initialize the data manager.
    _manager = [[FFManager alloc] init];
    
    // Initialize any needed arrays.
    recentStories = [[NSMutableArray alloc] initWithCapacity:10];
    authorImageCache = [[NSMutableDictionary alloc] initWithCapacity:20];
    categoryNames = [NSMutableArray arrayWithArray:@[]];
    
    // Update the title.
    [_navbar setTitle:@"Fanfiction"];
    
    // Initialize the recent stories list in Core Data.
    NSManagedObjectContext* context = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest* req = [[NSFetchRequest alloc] initWithEntityName:@"RecentStoryList"];
    NSMutableArray* reqArr = [[context executeFetchRequest:req error:nil] mutableCopy];
    //NSLog(@"Recent Stories: %@", reqArr);
    if(reqArr.count > 0){
        // Already have some recent stories saved.
        for(NSManagedObject* obj in reqArr){
            for(int i = 1; i <= 10; i++){
                NSString* name = [obj valueForKey:[NSString stringWithFormat:@"title%d", i]];
                if(!name) break;
                [recentStories addObject:name];
            }
        }
    } else {
        // Initialize a RecentStoryList.
        NSManagedObject* recentStoryList  = [NSEntityDescription insertNewObjectForEntityForName:@"RecentStoryList" inManagedObjectContext:context];
        for(int i = 1; i <= 10; i++){
            NSString* name = [NSString stringWithFormat:@"title%d", i];
            [recentStoryList setValue:nil forKey:name];
        }
        if(![context save:nil]) NSLog(@"Error saving!");
    }
}

- (void)displayLoadingIndicator {
    if(spinningBar) return;
    spinningBar = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinningBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    CGRect frame = spinningBar.frame;
    frame.size = CGSizeMake(40.0, 40.0);
    frame.origin.x = self.view.frame.size.width / 2 - frame.size.width / 2;
    frame.origin.y = self.view.frame.size.height / 2 - frame.size.height / 2;
    spinningBar.frame = frame;
    [spinningBar setHidden:NO];
    [self.view addSubview:spinningBar];
    [self.view bringSubviewToFront:spinningBar];
    [spinningBar startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)stopLoadingIndicator {
    [spinningBar stopAnimating];
    [spinningBar removeFromSuperview];
    spinningBar = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    // Initialize.
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
    
    // Reload the categories and their stories.
    //self.tableView.dataSource = nil;
    [self displayLoadingIndicator];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Fetch the new names.
        __block NSMutableArray* catNames = [self.manager getCategoryNamesForSource:FFNet];
        __block NSMutableArray* catStories = [[NSMutableArray alloc] initWithCapacity:catNames.count];
        for(NSUInteger i = 0; i < catNames.count; i++){
            NSLog(@"Getting stories for index %ld (%@)...", i, [catNames objectAtIndex:i]);
            [catStories addObject:[self.manager getCategoryStoriesForCategory:i source:FFNet]];
        }
        NSLog(@"Done refreshing main table.");
        
        // Reload the table view.
        dispatch_async(dispatch_get_main_queue(), ^{
            //self.tableView.dataSource = self;
            [self setCategoryStories:catStories];
            [self setCategoryNames:catNames];
            [self.tableView reloadData];
            [self stopLoadingIndicator];
        });
    });
    
    // Check if we are showing a specific story.
    if(_storyToShowDirectly){
        // Save value of and reset property.
        NSString* title = _storyToShowDirectly;
        _storyToShowDirectly = nil;
        NSLog(@"Showing directly: %@", title);
        
        // Save title in recents and reload table.
        NSLog(@"Inserting...");
        if([recentStories indexOfObject:title] != NSNotFound){
            [recentStories removeObject:title];
        }
        [recentStories insertObject:title atIndex:0];
        
        // Select the just-added row and inform its delegate as well.
        NSLog(@"Selecting...");
        NSUInteger sectionInd = [categoryNames indexOfObject:@"Recent"];
        NSIndexPath* path = [NSIndexPath indexPathForRow:0 inSection:sectionInd];
        [self.tableView selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:path];
        NSLog(@"Done showing directly.");
    }
    
    // Reload the table data.
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)browseCategories:(id)sender {
    [self performSegueWithIdentifier:@"browseSegue" sender:self];
}

- (void)insertNewObject:(id)sender {
    /*
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
     */
    [self performSegueWithIdentifier:@"searchSegue" sender:self];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSLog(@"Preparing for showDetail segue...");
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString* title;
        if([[categoryNames objectAtIndex:indexPath.section] isEqualToString:@"Recent"]){
            // Take the title from this class's own recent array.
            title = [recentStories objectAtIndex:indexPath.row];
            
            // Push title to front of recent list.
            [recentStories removeObject:title];
            [recentStories insertObject:title atIndex:0];
        } else {
            // Take the title from the FFManager-provided names.
            title = (NSString*)[(NSMutableArray*)[categoryStories objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            if([recentStories indexOfObject:title] != NSNotFound){
                [recentStories removeObject:title];
            }
            [recentStories insertObject:title atIndex:0];
        }
        
        // Remove any duplicates in the list of recents.
        [recentStories setArray:[[NSOrderedSet orderedSetWithArray:recentStories] array]];
        
        // Update the recent list.
        while(recentStories.count > 10){
            [recentStories removeLastObject];
        }
        
        // Save the recent list.
        NSManagedObjectContext* context = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
        NSFetchRequest* req = [[NSFetchRequest alloc] initWithEntityName:@"RecentStoryList"];
        NSMutableArray* reqArr = [[context executeFetchRequest:req error:nil] mutableCopy];
        //NSLog(@"Recent Stories: %@", reqArr);
        if(reqArr.count > 0){
            NSManagedObject* obj = [reqArr objectAtIndex:0];
            /*
            // Find the next available slot, if possible.
            bool found = false;
            for(int i = 1; i <= 10; i++){
                NSString* key = [NSString stringWithFormat:@"title%d", i];
                NSString* name = [obj valueForKey:key];
                if(!name){
                    found = true;
                    [obj setValue:title forKey:key];
                    break;
                }
            }
            
            // If no slot found, overwrite the least recent one and shift everything down.
            if(!found){
                for(int i = 10; i >= 2; i--){
                    NSString* key = [NSString stringWithFormat:@"title%d", i];
                    NSString* prevKey = [NSString stringWithFormat:@"title%d", (i - 1)];
                    [obj setValue:[obj valueForKey:prevKey] forKey:key];
                }
                [obj setValue:title forKey:@"title1"];
            }
             */
            // Save current recent list in Core Data.
            for(NSUInteger i = 1; i <= recentStories.count; i++){
                NSString* key = [NSString stringWithFormat:@"title%lu", (unsigned long)i];
                [obj setValue:[recentStories objectAtIndex:(i - 1)] forKey:key];
            }
            if(![context save:nil]) NSLog(@"Error saving recents!");
        }
        
        // Now perform the segue itself, providing the detail view controller with as much information as necessary.
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.manager = _manager;
        [controller setDetailItem:title];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        NSLog(@"Done preparing for showDetail.");
    } else if([[segue identifier] isEqualToString:@"searchSegue"]){
        AddSourceViewController* controller = (AddSourceViewController*)[segue destinationViewController];
        [controller setManager:_manager];
        [controller setMasterController:self];
        [controller setBrowsePathPrefix:_browsePathPrefix];
    } else if([[segue identifier] isEqualToString:@"browseSegue"]){
        BrowseViewController* controller = (BrowseViewController*)[segue destinationViewController];
        [controller setManager:_manager];
        [controller setMasterController:self];
        // TODO
        [controller setSource:FFNet];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //NSLog(@"Returning %ld categories", categoryNames.count);
    return [categoryNames count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //NSLog(@"Num. rows in section %ld with size %ld", section, categoryNames.count);
    if([[categoryNames objectAtIndex:section] isEqualToString:@"Recent"]){
        // Recent stories are tracked in this class, not FFManager.
        return recentStories.count;
    }
    return ((NSMutableArray*)[categoryStories objectAtIndex:section]).count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [categoryNames objectAtIndex:section];
}

- (void)asyncPopulateStoryCellAt:(NSIndexPath*)path inView:(UITableView*)theTableView forId:(NSString*)sid initialCell:(MasterViewCellTableViewCell*)initialCell {
    __block NSString* storyId = sid;
    MasterViewCellTableViewCell* cell = initialCell;
    //NSLog(@"Populating cell with ID %@", sid);
    if(!cell) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        cell.detailLabel.text = @"Loading details...";
        cell.descriptionLabel.text = @"Loading description...";
        cell.authorLabel.text = @"Loading...";
        [cell.authorImageView setImage:placeholderAuthorImage];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        //NSLog(@"Dispatch started!");
        // Retrieve story information (caching is handled in FFManager).
        __block FFStoryInfo* info = [_manager getInfoForStoryWithID:storyId fromSource:FFNet];
        
        // Download author image with a custom referrer field due to hotlinking protection.
        __block UIImage* authorImg;
        if(info && info->authorImgUrl){
            //NSLog(@"Image URL: %s", info->authorImgUrl);
            NSString* authorStrUrl = [NSString stringWithCString:info->authorImgUrl encoding:NSUTF8StringEncoding];
            if((authorImg = [authorImageCache objectForKey:authorStrUrl])){
                // Cached - do nothing.
            } else {
                NSURL* authorUrl = [NSURL URLWithString:authorStrUrl];
                NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:authorUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
                [request setHTTPMethod:@"GET"];
                [request setValue:@"https://www.fanfiction.net/s/123456/1" forHTTPHeaderField: @"Referer"];
                NSData* imgData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                authorImg = [UIImage imageWithData:imgData];
                if(authorImg){
                    [authorImageCache setObject:authorImg forKey:authorStrUrl];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Display story information in subtitle cell.
            MasterViewCellTableViewCell* cell = [theTableView cellForRowAtIndexPath:path];
            if(!cell) return;
            if(!info){
                cell.detailLabel.text = @"(Failed to load details)";
                cell.descriptionLabel.text = @"(Failed to load description)";
                cell.authorLabel.text = @"(Failed to load author)";
            } else {
                MarkupParser* p = [[MarkupParser alloc] init];
                [p setDefaultSize:10.0f];
                cell.authorLabel.text = [NSString stringWithFormat:@"%s", info->author];
                NSString* html = [NSString stringWithFormat:@"%s - <strong>Rated:</strong> %s - <strong>Chapters:</strong> %ld - <strong>Words:</strong> %s - <strong>Reviews:</strong> %ld - <strong>Favs:</strong> %s - <strong>Follows:</strong> %s", info->workName, info->rating, (unsigned long)info->chapterCount, info->wordNum, (unsigned long)info->reviewNum, info->favNum, info->followerNum];
                NSAttributedString* attStr = [p attrStringFromMarkup:html];
                cell.detailLabel.text = [attStr string];
                UIFont* fnt = [cell.descriptionLabel.font fontWithSize:20];
                CGSize constraint = cell.descriptionLabel.bounds.size;
                NSString* description = [NSString stringWithCharacters:info->description length:info->descriptionLength];
                for(int i = 20; i >= 7; i--){
                    fnt = [fnt fontWithSize:i];
                    CGSize labelSize = [description sizeWithFont:fnt constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
                    if(labelSize.height <= 55.0f) break;
                }
                cell.descriptionLabel.font = fnt;
                cell.descriptionLabel.text = description;
            }
            
            // Display the author image in the cell.
            if(info && authorImg){
                [cell.authorImageView setImage:authorImg]; // beauteous one-liner
            }
        });
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    __block MasterViewCellTableViewCell *cell = (MasterViewCellTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"MasterViewCell" forIndexPath:indexPath];
    
    // Get title of story, hiding the ID, but save the ID for later.
    NSString* title;
    if([[categoryNames objectAtIndex:indexPath.section] isEqualToString:@"Recent"]){
        // Take the title from this class's own recent array.
        title = [recentStories objectAtIndex:indexPath.row];
    } else {
        // Take the title from the FFManager-provided names.
        title = (NSString*)[(NSMutableArray*)[categoryStories objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    size_t pos = title.length - 1;
    while([title characterAtIndex:pos] != ' '){
        --pos;
    }
    NSRange idRange;
    idRange.location = pos + 2;
    idRange.length = (title.length - 1) - (pos + 2);
    NSString* storyId = [[title substringWithRange:idRange] copy];
    //NSLog(@"Story ID: %@", storyId);
    title = [title substringToIndex:pos];
    cell.titleLabel.text = title;
    
    // Dispatch a background task to retrieve story info and update cell accordingly.
    //[self dispatchCellFillIn:cell forId:storyId];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self asyncPopulateStoryCellAt:indexPath inView:tableView forId:storyId initialCell:cell];
    });
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"showDetail" sender:self];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // No items can be edited (yet?).
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [(NSMutableArray*)[categoryStories objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

@end
