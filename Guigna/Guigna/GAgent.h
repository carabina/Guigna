#import <Foundation/Foundation.h>

#import "GAdditions.h"

@interface GAgent : NSObject

@property(retain) id <GAppDelegate> appDelegate;
@property(assign) int processID; // TODO: array of PIDs

- (NSString *)outputForCommand:(NSString *)command;
- (NSArray *)nodesForURL:(NSString *)url XPath:(NSString *)xpath;

@end
