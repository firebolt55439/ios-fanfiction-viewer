//
//  FFManager.h
//  Fanfiction
//
//  Created by Sumer Kohli on 12/17/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProgressView.h"

typedef enum {
    FFNet // fanfiction.net
} FFSource;

typedef struct {
    const char* author; // story author
    const char* authorId; // author ID
    const char* authorImgUrl; // author image URL
    const char* rating; // story rating (e.g. Fiction T, etc.)
    const char* workName; // name of the work for which the fanfiction was composed (e.g. Star Wars, etc.)
    const unichar* description; // summary
    NSUInteger descriptionLength; // summary length
    NSUInteger chapterCount; // number of chapters
    const char* wordNum; // number of words
    NSUInteger reviewNum; // number of reviews
    const char* favNum; // number of favs
    const char* followerNum; // number of followers
} FFStoryInfo;

@class FFManager;

@interface FFManager : NSObject <NSURLSessionDownloadDelegate> {
    NSURLSessionDownloadTask* downloadTask;
}

@property (atomic) BOOL isDownloadDone, wasDownloadSuccessful; // for the download delegate
@property (weak, nonatomic) NSMutableArray* favoriteStories; // favorite stories

+ (NSString*)getStringIn:(NSString*)orig from:(NSString*)a to:(NSString*)b;
- (NSMutableArray*)getCategoryNamesForSource:(FFSource)source;
- (NSMutableArray*)getCategoryStoriesForCategory:(NSUInteger)categoryInd source:(FFSource)source;
- (NSString*)downloadStoryWithID:(NSString*)identifier fromSource:(FFSource)source chapter:(NSUInteger)ch progress:(ProgressView*)progressView;
- (FFStoryInfo*)getInfoForStoryWithID:(NSString*)identifier fromSource:(FFSource)source;
- (NSMutableArray*)getGenreNamesForSource:(FFSource)source;
- (NSMutableArray*)getTopForSource:(FFSource)source genre:(NSString*)genre crossover:(BOOL)crossover;

@end
