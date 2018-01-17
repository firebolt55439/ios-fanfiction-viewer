//
//  MarkupParser.m
//  Fanfiction
//
//  Created by Sumer Kohli on 12/18/15.
//  Copyright © 2015 Sumer Kohli. All rights reserved.
//

#import "MarkupParser.h"

#define DEFAULT_FONT @"ArialMT"

@implementation MarkupParser

@synthesize font, color, strokeColor, strokeWidth;
@synthesize images;

-(id)init
{
    self = [super init];
    if (self){
        self.font = DEFAULT_FONT;
        self.size = 20.0f;
        self.color = [UIColor blackColor];
        self.strokeColor = [UIColor whiteColor];
        self.strokeWidth = 0.0;
        self.images = [NSMutableArray array];
    }
    return self;
}

-(NSAttributedString*)attrStringFromMarkup:(NSString*)markup
{
    if(self.defaultFont) self.font = self.defaultFont;
    else self.defaultFont = self.font;
    if(self.defaultSize) self.size = self.defaultSize;
    else self.defaultSize = self.size;
    markup = [markup stringByReplacingOccurrencesOfString:@"\n" withString:@" "]; // replace manual newlines
    NSMutableAttributedString* aString = [[NSMutableAttributedString alloc] initWithString:@""]; //1
    
    NSRegularExpression* regex = [[NSRegularExpression alloc]
                                  initWithPattern:@"(.*?)(<[^>]+>|\\Z)"
                                  options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                  error:nil]; //2
    NSArray* chunks = [regex matchesInString:markup options:0
                                       range:NSMakeRange(0, [markup length])];
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    [paragraphStyle setFirstLineHeadIndent:30.0];
    [paragraphStyle setHeadIndent:10.0];
    NSMutableArray* fontStack = [[NSMutableArray alloc] initWithCapacity:3];
    [fontStack addObject:DEFAULT_FONT];
    NSUnderlineStyle underline = NSUnderlineStyleNone;
    //[paragraphStyle setTailIndent:20.0];
    for (NSTextCheckingResult* b in chunks) {
        NSArray* parts = [[markup substringWithRange:b.range]
                          componentsSeparatedByString:@"<"]; //1
        
        CTFontRef fontRef = CTFontCreateWithName((CFStringRef)self.font, self.size, NULL);
        
        // Apply the current text style.
        NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               (id)self.color.CGColor, kCTForegroundColorAttributeName,
                               (__bridge id)fontRef, kCTFontAttributeName,
                               (id)self.strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
                               (id)[NSNumber numberWithFloat: self.strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
                               [paragraphStyle copy], NSParagraphStyleAttributeName,
                               @(underline), NSUnderlineStyleAttributeName,
                               nil];
        [aString appendAttributedString:[[NSAttributedString alloc] initWithString:[parts objectAtIndex:0] attributes:attrs]];
        
        CFRelease(fontRef);
        
        // Handle new formatting tag.
        if ([parts count]>1) {
            NSString* tag = (NSString*)[parts objectAtIndex:1];
            if([tag rangeOfString:@" "].location != NSNotFound){
                NSRange range = [tag rangeOfString:@" "];
                NSString* before = [[tag substringToIndex:range.location] lowercaseString];
                NSString* after = [tag substringFromIndex:range.location];
                tag = [before stringByAppendingString:after];
            } else {
                tag = [tag lowercaseString];
            }
            if([tag hasPrefix:@"font"]){
                // Save current font on stack.
                [fontStack addObject:self.font];
                
                // Stroke color.
                NSRegularExpression* scolorRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=strokeColor=\")\\w+" options:0 error:NULL];
                [scolorRegex enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                    if ([[tag substringWithRange:match.range] isEqualToString:@"none"]) {
                        self.strokeWidth = 0.0;
                    } else {
                        self.strokeWidth = -3.0;
                        SEL colorSel = NSSelectorFromString([NSString stringWithFormat: @"%@Color", [tag substringWithRange:match.range]]);
                        self.strokeColor = [UIColor performSelector:colorSel];
                    }
                }];
                
                // Color.
                NSRegularExpression* colorRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=color=\")\\w+" options:0 error:NULL];
                [colorRegex enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                    SEL colorSel = NSSelectorFromString([NSString stringWithFormat: @"%@Color", [tag substringWithRange:match.range]]);
                    self.color = [UIColor performSelector:colorSel];
                }];
                
                // Face.
                NSRegularExpression* faceRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=face=\")[^\"]+" options:0 error:NULL];
                [faceRegex enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                    self.font = [tag substringWithRange:match.range];
                }];
            } else if([tag hasPrefix:@"/font"]){
                // Restore last font.
                self.font = [fontStack lastObject];
                [fontStack removeLastObject];
            } else if([tag hasPrefix:@"h1"] || [tag hasPrefix:@"/h1"]){
                if([tag hasPrefix:@"h1"]){
                    self.size = self.defaultSize * 1.32f;
                } else {
                    self.size = self.defaultSize;
                }
            } else if([tag hasPrefix:@"p"] || [tag hasPrefix:@"/p"] || [tag hasPrefix:@"br"]){
                [aString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            } else if([tag hasPrefix:@"em"] || [tag hasPrefix:@"/em"] || [tag hasPrefix:@"strong"] || [tag hasPrefix:@"/strong"] || [tag hasPrefix:@"i>"] || [tag hasPrefix:@"/i>"]){
                if([tag hasPrefix:@"em"] || [tag hasPrefix:@"strong"] || [tag hasPrefix:@"i>"]){
                    UIFont* plainFont = [UIFont fontWithName:self.font size:self.size];
                    [fontStack addObject:self.font];
                    UIFontDescriptorSymbolicTraits trait = (([tag hasPrefix:@"em"] || [tag hasPrefix:@"i>"]) ? UIFontDescriptorTraitItalic : UIFontDescriptorTraitBold);
                    self.font = [[UIFont fontWithDescriptor:[[plainFont fontDescriptor] fontDescriptorWithSymbolicTraits:trait] size:self.size] fontName];
                } else {
                    self.font = [fontStack lastObject];
                    [fontStack removeLastObject];
                }
            } else if([tag hasPrefix:@"span"] || [tag hasPrefix:@"/span"]){
                if([tag hasPrefix:@"span"]){
                    if([tag rangeOfString:@"text-decoration: underline"].location != NSNotFound){
                        underline = NSUnderlineStyleSingle;
                    }
                } else {
                    underline = NSUnderlineStyleNone;
                }
            } else if([tag hasPrefix:@"center"] || [tag hasPrefix:@"/center"]){
                if([tag hasPrefix:@"center"]){
                    [paragraphStyle setAlignment:NSTextAlignmentCenter];
                    [paragraphStyle setFirstLineHeadIndent:0.0];
                    [paragraphStyle setHeadIndent:0.0];
                } else {
                    [paragraphStyle setAlignment:NSTextAlignmentNatural];
                    [paragraphStyle setFirstLineHeadIndent:30.0];
                    [paragraphStyle setHeadIndent:10.0];
                }
            } else if([tag hasPrefix:@"hr"]){
                NSMutableParagraphStyle* dup = [paragraphStyle mutableCopy];
                [dup setAlignment:NSTextAlignmentCenter];
                [dup setFirstLineHeadIndent:0.0];
                [dup setHeadIndent:0.0];
                NSMutableDictionary* dupAttrs = [attrs mutableCopy];
                [dupAttrs setObject:dup forKey:NSParagraphStyleAttributeName];
                [aString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n-----\n" attributes:dupAttrs]];
            } else {
                NSLog(@"Unknown markup tag: %@", tag);
            }
        }
    }
    
    return (NSAttributedString*)aString;
}

-(void)dealloc {
    self.font = nil;
    self.color = nil;
    self.strokeColor = nil;
    self.images = nil;
}

@end