//
//  BrowseViewController.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/23/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "BrowseViewController.h"
#import "MasterViewController.h"

@interface BrowseViewController ()

@end

@implementation BrowseViewController {
    NSMutableArray* categoryNames;
    UIPickerView* pickerView;
    NSMutableArray *regularTitleNames, *crossoverTitleNames;
    UIActivityIndicatorView* spinningBar;
    NSInteger selectedRow, selectedSection;
    NSString* currentGenreName;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Initialize the data for the picker view.
    categoryNames = [NSMutableArray arrayWithArray:@[]];
    
    // Set up the table and picker view.
    selectedRow = selectedSection = -1;
    _titlesTable.delegate = self;
    _titlesTable.dataSource = self;
    pickerView = [[UIPickerView alloc] init];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    _categoryTextField.inputView = pickerView;
}

- (void)viewDidAppear:(BOOL)animated {
    // Initialize the data for the picker view.
    [self displayLoadingIndicator];
    categoryNames = [_manager getGenreNamesForSource:_source];
    NSLog(@"Genre names: %@", categoryNames);
    [pickerView reloadAllComponents];
    [self stopLoadingIndicator];
}

- (void)viewWillDisappear:(BOOL)animated {
    // Notify the main controller of the selection, if applicable.
    NSString* selection = @"";
    if(selectedRow != -1 && selectedSection != -1){
        selection = (selectedSection == 0 ? [regularTitleNames objectAtIndex:selectedRow] : [crossoverTitleNames objectAtIndex:selectedRow]);
        selection = [selection lowercaseString];
        NSUInteger pos = selection.length - 1;
        while([selection characterAtIndex:pos] != ' ') --pos;
        selection = [selection substringToIndex:pos];
        selection = [selection stringByReplacingOccurrencesOfString:@" " withString:@"-"];
        NSString* genre = currentGenreName;
        genre = [genre lowercaseString];
        if([genre characterAtIndex:(genre.length - 1)] == 's') genre = [genre substringToIndex:(genre.length - 1)];
        if(selectedSection == 1) selection = [NSString stringWithFormat:@"crossovers/%@/%@/", genre, selection];
        else selection = [NSString stringWithFormat:@"%@/%@/", genre, selection];
    }
    [(MasterViewController*)_masterController setBrowsePathPrefix:selection];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

// Updates the table view for the currently-selected genre.
- (void)dispatchUpdateTable {
    // Download the top 200 lists for the genre, regular and crossover.
    [self performSelectorOnMainThread:@selector(displayLoadingIndicator) withObject:nil waitUntilDone:NO];
    NSString* genre = [categoryNames objectAtIndex:[pickerView selectedRowInComponent:0]];
    currentGenreName = genre;
    regularTitleNames = [_manager getTopForSource:_source genre:genre crossover:NO];
    crossoverTitleNames = [_manager getTopForSource:_source genre:genre crossover:YES];
    [_titlesTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(stopLoadingIndicator) withObject:nil waitUntilDone:NO];
}

#pragma mark - UIPickerViewDelegate

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return categoryNames.count;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [categoryNames objectAtIndex:row];
}

-(void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    // Update the text field and resign first responder.
    _categoryTextField.text = [categoryNames objectAtIndex:row];
    [_categoryTextField performSelectorOnMainThread:@selector(resignFirstResponder) withObject:nil waitUntilDone:YES];
    
    // Update the table accordingly.
    [self performSelectorInBackground:@selector(dispatchUpdateTable) withObject:nil];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // regular and crossovers
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) return @"Regular";
    else return @"Crossovers";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) return regularTitleNames.count;
    else return crossoverTitleNames.count;
}

- (UITableViewCell*)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:@"BrowseCellID" forIndexPath:indexPath];
    
    // Get name and number.
    NSString* title;
    if(indexPath.section == 0) title = [regularTitleNames objectAtIndex:indexPath.row];
    else title = [crossoverTitleNames objectAtIndex:indexPath.row];
    size_t pos = title.length - 1;
    while([title characterAtIndex:pos] != ' '){
        --pos;
    }
    NSRange idRange;
    idRange.location = pos + 2;
    idRange.length = (title.length - 1) - (pos + 2);
    NSString* storyNum = [title substringWithRange:idRange];
    title = [title substringToIndex:pos];
    
    // Fill in cell.
    cell.textLabel.text = title;
    cell.detailTextLabel.text = storyNum;
    if(indexPath.section == selectedSection && indexPath.row == selectedRow){
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(selectedRow != -1){
        [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow inSection:selectedSection]].accessoryType = UITableViewCellAccessoryNone;
    }
    if(selectedRow != indexPath.row || selectedSection != indexPath.section){ // double-selecting unselects
        selectedSection = indexPath.section;
        selectedRow = indexPath.row;
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        selectedSection = selectedRow = -1;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
