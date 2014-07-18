#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@protocol GAppDelegate
@property(strong) NSMutableArray *allPackages;
- (NSUserDefaultsController *)defaults;
- (void)log:(NSString*)msg;
- (NSInteger)shellColumns;

@end


@interface NSArray (GAdditions)
- (NSString *)join;
- (NSString *)join:(NSString *)separator;
@end

@interface NSString (GAdditions)
- (BOOL)is:(NSString *)string;
- (BOOL)contains:(NSString *)string;
- (NSArray *)split;
- (NSArray *)split:(NSString *)delimiter;
@end

@interface NSXMLNode (GAdditions)
- (NSArray *)nodesForXPath:(NSString *)xpath;
- objectForKeyedSubscript:xpath;
@end

@interface NSXMLElement (GAdditions)
- objectForKeyedSubscript:(NSString *)xpath;
- (NSString *)href;
@end

@interface NSUserDefaultsController (GAdditions)
- objectForKeyedSubscript:key;
- (void)setObject:value forKeyedSubscript:key;
@end

@interface WebView (GAdditions)
- (void)swipeWithEvent:(NSEvent *)event;
- (void)magnifyWithEvent:(NSEvent *)event;
@end
