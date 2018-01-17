//
//  FFManager.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/17/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "FFManager.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#include <iostream>
#include <string>

@implementation FFManager {
    NSMutableDictionary* authorNamesToId; // author [name] --> [id]
    NSMutableDictionary* storyInfoCache; // story info cache
    ProgressView* progressView;
    NSString* finalDownloadData;
    NSMutableArray* categoryNames; // last generated category names
}

@synthesize isDownloadDone;
@synthesize wasDownloadSuccessful;

- (id)init {
    if(self = [super init]){
        authorNamesToId = [[NSMutableDictionary alloc] initWithCapacity:5];
        storyInfoCache = [[NSMutableDictionary alloc] initWithCapacity:20];
    }
    return self;
}

// Return a substring between two strings in a given string, if applicable.
+ (NSString*)getStringIn:(NSString*)orig from:(NSString*)a to:(NSString*)b {
    NSRange range = [orig rangeOfString:a];
    NSUInteger startLocation = range.location;
    if(startLocation == NSNotFound) return nil;
    range = [[orig substringFromIndex:(range.location + range.length)] rangeOfString:b];
    NSUInteger endLocation = range.location;
    if(endLocation == NSNotFound) return nil;
    endLocation += startLocation + a.length;
    startLocation += a.length;
    range.location = startLocation;
    range.length = endLocation - startLocation;
    return [orig substringWithRange:range];
}

// Get all category names for a specified source.
- (NSMutableArray*)getCategoryNamesForSource:(FFSource)source {
    if(source == FFNet){
        categoryNames = [NSMutableArray arrayWithArray:@[@"Recommended", @"Recent", @"Favorite Stories", @"Favorite Authors"]];
        NSManagedObjectContext* context = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
        NSFetchRequest* req = [[NSFetchRequest alloc] initWithEntityName:@"FavAuthor"];
        NSMutableArray* reqArr = [[context executeFetchRequest:req error:nil] mutableCopy];
        NSLog(@"Saved Authors: %@", reqArr);
        if(reqArr.count > 0){
            // Already have some authors saved.
            for(NSManagedObject* obj in reqArr){
                NSString* name = [obj valueForKey:@"name"];
                [categoryNames addObject:[NSString stringWithFormat:@"Author: %@", name]];
                [authorNamesToId setObject:[obj valueForKey:@"authorId"] forKey:name];
            }
        } else {
            // Populate a list with a few starters.
            NSManagedObject* theRealThing = [NSEntityDescription insertNewObjectForEntityForName:@"FavAuthor" inManagedObjectContext:context];
            [theRealThing setValue:@"1030187" forKey:@"authorId"];
            [theRealThing setValue:@"TheRealThing" forKey:@"name"];
            if(![context save:nil]) NSLog(@"Error saving!");
        }
    } else {
        categoryNames = [NSMutableArray arrayWithArray:@[]];
    }
    return categoryNames;
}

- (NSMutableArray*)getCategoryStoriesForCategory:(NSUInteger)categoryInd source:(FFSource)source {
    // Returns ID of stories by category index.
    if(source == FFNet){
        if(categoryInd > 3){
            NSString* categoryName = [categoryNames objectAtIndex:categoryInd];
            NSLog(@"Requested category with name %@", categoryName);
            return [self getAllStoriesByAuthor:[authorNamesToId objectForKey:[categoryName stringByReplacingOccurrencesOfString:@"Author: " withString:@""]] source:source];
        }
    }
    return [NSMutableArray arrayWithArray:@[]];
}

- (NSMutableArray*)getAllStoriesByAuthor:(NSString*)authorID source:(FFSource)source {
    // <div id='st_inside'>
    // <div id='fa'
    if(source == FFNet){
        // Download author's XML feed.
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://fanfiction.net/atom/u/%@", authorID]];
        NSString* data = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        //data = [FFManager getStringIn:data from:@"<div id='st_inside'>" to:@"<div id='fa'"];
        //NSLog(@"Data: %@", data);
        
        // Scrape the feed for story title's and ID's.
        NSMutableArray* ret = [[NSMutableArray alloc] initWithCapacity:10];
        /*
        std::string dt([data cStringUsingEncoding:NSUTF8StringEncoding]);
        size_t pos = 0;
        while((pos = dt.find("data-storyid=", pos)) != std::string::npos){
            // Extract the story ID.
            size_t id_start = pos + 14, id_end = pos + 14;
            while(dt[id_end] != '"') ++id_end;
            std::string story_id(dt.substr(id_start, id_end - id_start));
            
            // Extract the story title.
            pos = dt.find("data-title=", pos);
            size_t title_start = pos + 12, title_end = pos + 12;
            while(dt[title_end] != '"') ++title_end;
            std::string story_title(dt.substr(title_start, title_end - title_start));
            [ret addObject:[[NSString stringWithFormat:@"%s (%s)", story_title.c_str(), story_id.c_str()] stringByReplacingOccurrencesOfString:@"\\" withString:@""]];
        }
         */
        NSString* after = data;
        if([data rangeOfString:@"<entry>"].location == NSNotFound) return ret;
        after = [after substringFromIndex:[data rangeOfString:@"<entry>"].location];
        NSUInteger loc;
        while((loc = [after rangeOfString:@"</updated>"].location) != NSNotFound){
            after = [after substringFromIndex:(loc + 1)];
            NSString* title = [FFManager getStringIn:after from:@"<title>" to:@"</title>"];
            NSString* storyId = [FFManager getStringIn:after from:@":story." to:@"</id>"];
            [ret addObject:[NSString stringWithFormat:@"%@ (%@)", title, storyId]];
        }
        NSLog(@"Ret: %@", ret);
        return ret;
    }
    return [NSMutableArray arrayWithArray:@[]];
}

- (NSMutableArray*)getGenreNamesForSource:(FFSource)source {
    if(source == FFNet){
        NSMutableArray* ret = [NSMutableArray arrayWithCapacity:9];
        
        // Download the main page.
        NSError* err;
        NSURL* theUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://m.fanfiction.net"]];
        NSURLRequest* request = [NSURLRequest requestWithURL:theUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:4];
        NSData* urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
        if(err){
            NSLog(@"Error getting info: %@", err);
            return ret;
        }
        NSString* data = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
        
        // Scrape for any and all category names.
        NSString* at = data;
        NSUInteger loc;
        NSLog(@"Have %ld chars", (unsigned long)at.length);
        while((loc = [at rangeOfString:@"<img src='/static/fcons/script-text.png'"].location) != NSNotFound){
            at = [at substringFromIndex:(loc + 1)];
            NSString* name = [FFManager getStringIn:at from:@"'>" to:@"</a>"];
            [ret addObject:name];
            NSLog(@"Got name: %@", name);
        }
        return ret;
    }
    return [NSMutableArray arrayWithArray:@[]];
}

- (NSMutableArray*)getTopForSource:(FFSource)source genre:(NSString*)genre crossover:(BOOL)crossover {
    if(source == FFNet){
        NSMutableArray* ret = [NSMutableArray arrayWithCapacity:200];
        
        // Download the genre page.
        NSError* err;
        NSURL* theUrl;
        genre = [genre lowercaseString];
        if([genre characterAtIndex:(genre.length - 1)] == 's') genre = [genre substringToIndex:(genre.length - 1)];
        if(crossover) theUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://m.fanfiction.net/crossovers/%@/", genre]];
        else theUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://m.fanfiction.net/%@/", genre]];
        NSURLRequest* request = [NSURLRequest requestWithURL:theUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:4];
        NSData* urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
        if(err){
            NSLog(@"Error getting top 200: %@", err);
            return ret;
        }
        NSString* data = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
        
        // Scrape for title and story number.
        NSString* at = data;
        NSUInteger loc;
        //NSLog(@"Have %ld chars - %@ - %@", at.length, theUrl, data);
        while((loc = [at rangeOfString:@"<div class='bs"].location) != NSNotFound){
            at = [at substringFromIndex:(loc + 1)];
            NSString* roi = [FFManager getStringIn:at from:@"<a" to:@"</a>"];
            NSString* name = [FFManager getStringIn:roi from:@"\">" to:@"<span"];
            NSString* num = [FFManager getStringIn:roi from:@"<span" to:@"</span>"];
            num = [num substringFromIndex:([num rangeOfString:@"'>"].location + 2)];
            NSString* category = [NSString stringWithFormat:@"%@ (%@)", name, num];
            [ret addObject:category];
            //NSLog(@"Got category: %@", category);
        }
        NSLog(@"Got %ld titles.", (unsigned long)ret.count);
        //NSLog(@"Last loc: %ld", loc);
        return ret;
    }
    return [NSMutableArray arrayWithArray:@[]];
}

- (NSURL*)urlForStoryWithID:(NSString*)identifier fromSource:(FFSource)source chapter:(NSUInteger)ch mobile:(BOOL)mobile {
    NSString* url = @"https://";
    switch(source){
        case FFNet:
            if(!mobile) url = [url stringByAppendingString:@"www.fanfiction.net/s/"];
            else url = [url stringByAppendingString:@"m.fanfiction.net/s/"];
            url = [url stringByAppendingFormat:@"%@/%lu", identifier, (unsigned long)ch];
            break;
        default:
            NSLog(@"Unknown source selected.");
            exit(EXIT_FAILURE);
    }
    NSURL* theUrl = [NSURL URLWithString:url];
    return theUrl;
}

- (FFStoryInfo*)getInfoForStoryWithID:(NSString*)identifier fromSource:(FFSource)source {
    // Check if the story has been cached first.
    FFStoryInfo* info;
    if([storyInfoCache objectForKey:identifier]){
        // If so, do nothing - the result has been cached.
        FFStoryInfo* info = (FFStoryInfo*)[[storyInfoCache objectForKey:identifier] pointerValue];
        //NSLog(@"CACHE HIT!");
        return info;
    }
    
    // Generate the URL string to download from.
    NSURL* theUrl = [self urlForStoryWithID:identifier fromSource:source chapter:1 mobile:YES];
    
    // Download the page.
    NSError* err;
    NSURLRequest* request = [NSURLRequest requestWithURL:theUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:4];
    NSData* urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
    if(err){
        NSLog(@"Error getting info: %@", err);
        return nil;
    }
    //NSString* data = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil];
    NSString* data = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
    //NSLog(@"Finished actual download.");
    
    // Extract necessary information. //
    FFStoryInfo* ret = (FFStoryInfo*)malloc(sizeof(FFStoryInfo));
    
    // Author name and ID.
    //NSLog(@"ID: %@ - URL: %@ - %ld", identifier, theUrl, data.length);
    NSString* roi = [FFManager getStringIn:data from:@"<a href='/u/" to:@"</a>"];
    //NSLog(@"ROI: %@", roi);
    if(roi == nil) return nil; // in case of an invalid story ID
    ret->authorId = strdup([[roi substringToIndex:[roi rangeOfString:@"'>"].location] cStringUsingEncoding:NSUTF8StringEncoding]);
    ret->author = strdup([[roi substringFromIndex:([roi rangeOfString:@"'>"].location + 2)] cStringUsingEncoding:NSUTF8StringEncoding]);
    //NSLog(@"Author: %s", ret->author);
    [authorNamesToId setObject:[NSString stringWithUTF8String:ret->authorId] forKey:[NSString stringWithUTF8String:ret->author]];
    
    // Author image URL.
    roi = [FFManager getStringIn:data from:@"<div id=img_large" to:@"Follow/Fav"];
    NSString* authorUrl;
    if(roi){
        authorUrl = [FFManager getStringIn:roi from:@"src='//ffcdn" to:@"' width="];
        if(authorUrl){
            authorUrl = [@"https://ffcdn" stringByAppendingString:authorUrl];
        }
    }
    if(authorUrl){
        ret->authorImgUrl = strdup([authorUrl cStringUsingEncoding:NSUTF8StringEncoding]);
    } else {
        ret->authorImgUrl = NULL;
    }
    
    // Description.
    err = nil;
    NSString* atom = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.fanfiction.net/atom/u/%s/", ret->authorId]] encoding:NSUTF8StringEncoding error:&err];
    __strong NSString* description;
    if(err){
        description = @"(Unable to retrieve description)";
    } else {
        NSString* after = [atom substringFromIndex:[atom rangeOfString:[NSString stringWithFormat:@"story.%@", identifier]].location];
        description = [FFManager getStringIn:after from:@"hr size=1&gt;" to:@"</summary>"];
        description = [description stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    }
    //NSLog(@"Summary: %@", description);
    NSData* desc = [description dataUsingEncoding:NSUnicodeStringEncoding];
    const unichar* descCopy = (const unichar*)malloc(desc.length);
    memcpy((void*)descCopy, desc.bytes, desc.length);
    ret->description = descCopy;
    ret->descriptionLength = description.length + 1;
    //NSLog(@"Data restored: |%@|", [NSString stringWithCharacters:ret->description length:ret->descriptionLength]);
    
    // Category (Work) Name.
    NSString* after = [data substringFromIndex:[data rangeOfString:@"<hr size=1 noshade>"].location];
    NSString* workName = [FFManager getStringIn:after from:@"<a href=\"" to:@"</a>"];
    workName = [workName substringFromIndex:([workName rangeOfString:@"\">"].location + 2)];
    ret->workName = strdup([workName cStringUsingEncoding:NSUTF8StringEncoding]);
    
    // Rating.
    ret->rating = strdup([[FFManager getStringIn:data from:@"</a> Rated:" to:@","] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    // Chapter and word count.
    NSUInteger afterLoc = [data rangeOfString:@"</script><!-- end ad --></div>"].location;
    if(afterLoc == NSNotFound) afterLoc = 0;
    after = [data substringFromIndex:afterLoc];
    ret->wordNum = strdup([[FFManager getStringIn:after from:@"Words:" to:@","] cStringUsingEncoding:NSUTF8StringEncoding]);
    ret->chapterCount = [[FFManager getStringIn:after from:@"var chs = " to:@";"] intValue];
    if(ret->chapterCount == 0) ret->chapterCount = 1; // 'Chapter: ...' does not show for single-chapter stories
    
    // Review, favorite, and follower count.
    ret->reviewNum = [[[FFManager getStringIn:after from:@"<img src='/static/fcons/balloon.png' class='mt icons'>" to:@"</a>"] stringByReplacingOccurrencesOfString:@"," withString:@""] intValue];
    char* favs = (char*)[[FFManager getStringIn:after from:@"Favs:" to:@","] cStringUsingEncoding:NSUTF8StringEncoding];
    if(!favs) favs = (char*)"0";
    ret->favNum = strdup(favs);
    char* follows = (char*)[[FFManager getStringIn:after from:@"Follows:" to:@","] cStringUsingEncoding:NSUTF8StringEncoding];
    if(!follows) follows = (char*)"0";
    ret->followerNum = strdup(follows);
    
    // Save info to cache.
    if(info){
        [storyInfoCache setObject:[NSValue valueWithPointer:ret] forKey:identifier];
    }
    
    // Return.
    return ret;
}

- (NSString*)downloadStoryWithID:(NSString*)identifier fromSource:(FFSource)source chapter:(NSUInteger)ch progress:(ProgressView *)progView {
    // Generate the URL string to download from.
    NSURL* theUrl = [self urlForStoryWithID:identifier fromSource:source chapter:ch mobile:NO];
    
    // Download the file at the given URL.
    NSError *err;
    NSString* data = [NSString stringWithContentsOfURL:theUrl encoding:NSUTF8StringEncoding error:&err];
    if(err){
        NSLog(@"Download error: %@", err.description);
        return @"";
    }
    finalDownloadData = nil;
    
    // Perform a source-specific parsing of the data.
    NSString* parsed = nil;
    if(source == FFNet){
        NSRange range = [data rangeOfString:@"<div class='storytext xcontrast_txt nocopy' id='storytext'>"];
        NSUInteger startLocation = range.location;
        if(startLocation != NSNotFound){
            NSUInteger endLocation = [[data substringFromIndex:startLocation] rangeOfString:@"</div>"].location;
            if(endLocation == NSNotFound) return @"";
            endLocation += startLocation;
            range.location = startLocation;
            range.length = endLocation - startLocation;
            NSString* body = [data substringWithRange:range];
            parsed = body;
        }
    }
    NSLog(@"Parsed: %@...", [parsed substringToIndex:MIN(parsed.length, 100)]);
    return parsed;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)createDownloadTask:(NSURL*)url {
    NSMutableURLRequest* downloadRequest = [NSMutableURLRequest requestWithURL:url];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    downloadTask = [session downloadTaskWithRequest:downloadRequest];
    [downloadTask resume];
    NSLog(@"%ld", (long)[downloadTask state]);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"didWriteData called");
    if(totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) NSLog(@"UNKNOWN!!!");
    NSLog(@"%lld / %lld", totalBytesWritten, totalBytesExpectedToWrite);
    double progress = (double)(totalBytesWritten) / (double)(totalBytesExpectedToWrite);
    NSLog(@"Current progress: %f", progress);
    [progressView animateProgressViewToProgress:progress];
    [progressView updateProgressViewLabelWithProgress:(progress * 100.0f)];
    [progressView updateProgressViewWith:totalBytesWritten totalFileSize:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSError* err;
    finalDownloadData = [NSString stringWithContentsOfURL:location encoding:NSUTF8StringEncoding error:&err];
    if(err){
        NSLog(@"Error downloading: %@", err);
        wasDownloadSuccessful = NO;
    } else {
        wasDownloadSuccessful = YES;
    }
    isDownloadDone = YES;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error == nil) return;
    NSLog(@"Error downloading (dCWE): %@", [error description]);
    wasDownloadSuccessful = NO;
    isDownloadDone = YES;
    finalDownloadData = nil;
}

@end