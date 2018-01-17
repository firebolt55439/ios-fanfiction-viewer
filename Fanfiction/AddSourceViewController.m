//
//  AddSourceViewController.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/20/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "AddSourceViewController.h"
#import "MasterViewController.h"
#import "MasterViewCellTableViewCell.h"

@interface AddSourceViewController () {
    NSMutableArray* searchResults; // contains "Story name (ID)"
    NSString* lastSearch; // contains the last thing searched for (will be accessed by multiple threads)
    UIActivityIndicatorView* spinningBar; // loading bar
}

@end

@implementation AddSourceViewController

@synthesize tableView;
@synthesize searchController;

- (IBAction)prepareForUnwind:(UIStoryboardSegue*)segue {
    NSLog(@"Unwinding search!");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    searchResults = [NSMutableArray arrayWithArray:@[/*@"Out of the Darkness (6621882)"*/]];
    [self.tableView registerClass:[MasterViewCellTableViewCell class] forCellReuseIdentifier:@"MasterViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MasterViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"MasterViewCell"];
    self.tableView.estimatedRowHeight = self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.rowHeight = 180.0f;
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.tableView setNeedsLayout];
    [self.tableView layoutIfNeeded];
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.dimsBackgroundDuringPresentation = NO;
    self.definesPresentationContext = YES;
    tableView.tableHeaderView = searchController.searchBar;
    
    // Show top stories in section if a prefix path has been selected.
    if(_browsePathPrefix.length > 0){
        [self displayLoadingIndicator];
        __weak __typeof(self) weakSelf = self;
        __block __weak NSMutableArray* weakSearchResultsOrig = searchResults;
        __block __weak NSString* prefix = _browsePathPrefix;
        __block NSMutableArray* weakSearchResults = [[NSMutableArray alloc] initWithCapacity:20];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSString* url = [NSString stringWithFormat:@"https://m.fanfiction.net/%@?srt=3&t=0&g1=0&g2=0&r=10&lan=0&len=0&s=0&v1=0&c1=0&c2=0&c3=0&c4=0&_g1=0&_c1=0&_c2=0&_v1=0", prefix];
            NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:0 timeoutInterval:4];
            NSError* err;
            NSData* urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
            if(err) return;
            NSString* data = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
            [self parseSearchPage:data toArray:weakSearchResults];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSearchResultsOrig removeAllObjects];
                [weakSearchResultsOrig addObjectsFromArray:weakSearchResults];
                [weakSelf.tableView reloadData];
                [weakSelf stopLoadingIndicator];
            });
        });
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

- (NSUInteger)parseSearchPage:(NSString*)after toArray:(NSMutableArray*)weakSearchResults {
    NSUInteger lastNum = 0;
    while([after rangeOfString:@"href=\"/s"].location != NSNotFound){
        after = [after substringFromIndex:([after rangeOfString:@"href=\"/s"].location + 9)];
        NSUInteger at = 0;
        while(at < after.length && [after characterAtIndex:at] != '/') ++at;
        if((at + 2) < after.length){
            if(![[after substringFromIndex:at] hasPrefix:@"/1/"]) continue;
        }
        NSString* storyId = [after substringToIndex:[after rangeOfString:@"/1"].location];
        NSString* storyTitle = [FFManager getStringIn:after from:@"\">" to:@"</a>"];
        storyTitle = [storyTitle stringByAppendingString:[NSString stringWithFormat:@" (%@)", storyId]];
        storyTitle = [storyTitle stringByReplacingOccurrencesOfString:@"<b>" withString:@""];
        storyTitle = [storyTitle stringByReplacingOccurrencesOfString:@"</b>" withString:@""];
        [weakSearchResults addObject:storyTitle];
        //NSLog(@"Next title: %@ / length: %ld", storyTitle, after.length);
        ++lastNum;
    }
    return lastNum;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UISearchResultsUpdating

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    if(scope == nil) scope = @"All";
    [tableView reloadData];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // Figure out what was typed.
    __block NSString* searched = searchController.searchBar.text;
    searched = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                     (CFStringRef)searched,
                                                                     NULL,
                                                                     (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                     kCFStringEncodingUTF8 ));
    NSLog(@"Searched: %@", searched);
    lastSearch = searched;
    if(searched.length == 0) return;
    
    // Dispatch a background task to search.
    __weak __typeof(self) weakSelf = self;
    const NSUInteger RESULTS_MAX = 50;
    __block __weak NSMutableArray* weakSearchResultsOrig = searchResults;
    __block __weak NSString* prefix = _browsePathPrefix;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        __block NSMutableArray* weakSearchResults = [[NSMutableArray alloc] initWithCapacity:RESULTS_MAX];
        
        // Generate the format string used for the URL.
        NSLog(@"Browse prefix: %@", prefix);
        NSString* urlFormat = @"https://m.fanfiction.net/search.php?type=story&keywords=%@&match=title&sort=0&ppage=%ld&ready=1";
        if(prefix.length > 0){
            NSString* url = [NSString stringWithFormat:@"https://www.fanfiction.net/%@", prefix];
            NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:0 timeoutInterval:4];
            NSError* err;
            NSData* urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
            if(!err){
                NSString* data = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
                NSString* categoryId = [FFManager getStringIn:data from:@"&cid1=" to:@"&r="];
                if(categoryId){
                    urlFormat = @"https://m.fanfiction.net/search.php?keywords=%@&type=story&match=title&formatid=any&sort=0&genreid1=0&genreid2=0&characterid1=0&characterid2=0&characterid3=0&characterid4=0&words=0&ready=1&ppage=%ld&categoryid=";
                    urlFormat = [urlFormat stringByAppendingString:categoryId];
                }
            }
        }
        NSLog(@"URL Format: %@", urlFormat);
        
        // Download the search URL by pages repeatedly up to a maximum number of results.
        NSLog(@"Downloading search results...");
        NSUInteger page = 1, lastNum = 1, total = 0;
        while(lastNum > 0 && total <= RESULTS_MAX){
            if(![lastSearch isEqualToString:searched]) return;
            NSString* url = [NSString stringWithFormat:urlFormat, searched, page];
            NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:0 timeoutInterval:4];
            NSError* err;
            NSData* urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
            if(err) break;
            //NSString* data = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil];
            NSString* data = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
            
            // Scrape the data for titles and ID's.
            lastNum = [self parseSearchPage:data toArray:weakSearchResults];
            total += lastNum;
            ++page;
        }
        NSLog(@"Parsed %ld total results.", total);
        dispatch_async(dispatch_get_main_queue(), ^{
            if(![lastSearch isEqualToString:searched]) return;
            [weakSearchResultsOrig removeAllObjects];
            [weakSearchResultsOrig addObjectsFromArray:weakSearchResults];
            [weakSelf.tableView reloadData];
        });
        NSLog(@"Done.");
    });
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // TODO
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // TODO
    NSLog(@"Number of rows: %ld", searchResults.count);
    return [searchResults count];
}

- (UITableViewCell*)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row >= searchResults.count) return nil;
    
    __block MasterViewCellTableViewCell *cell = (MasterViewCellTableViewCell*)[theTableView dequeueReusableCellWithIdentifier:@"MasterViewCell" forIndexPath:indexPath];
    
    // Get title of story, hiding the ID, but save the ID for later.
    NSString* title = (NSString*)[searchResults objectAtIndex:indexPath.row];
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [(MasterViewController*)self.masterController asyncPopulateStoryCellAt:indexPath inView:theTableView forId:storyId initialCell:cell];
    });
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Figure out what story was clicked.
    __block __strong NSString* title = [searchResults objectAtIndex:indexPath.row];
    NSLog(@"Did select row #%ld with title %@", indexPath.row, title);
    
    // Exit view.
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // Pass on object before exiting.
        [(MasterViewController*)weakSelf.masterController setStoryToShowDirectly:title];
        
        // Exit.
        //[weakSelf.navigationController resignFirstResponder];
        //[weakSelf performSegueWithIdentifier:@"exitSegue" sender:self];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    });
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
