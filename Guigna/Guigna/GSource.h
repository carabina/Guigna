#import <Foundation/Foundation.h>

@class GItem;
@class GAgent;


typedef NS_ENUM(NSInteger, GState) {
    GOffState = 0,
    GOnState,
    GHiddenState
};

typedef NS_ENUM(NSInteger, GMode) {
    GOfflineMode = 0,
    GOnlineMode
};


@interface GSource : NSObject

@property(strong) NSString *name;
@property(strong) NSMutableArray *categories;
@property(strong) NSMutableArray *items;
@property(assign) GState status;
@property(assign) GMode mode;
@property(strong) NSString *homepage;
@property(strong) GAgent *agent;
@property(strong) NSString *cmd;

- (instancetype)initWithName:(NSString *)name agent:(GAgent *)agent;
- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithAgent:(GAgent *)agent;


- (NSString *)info:(GItem *)item;
- (NSString *)home:(GItem *)item;
- (NSString *)log:(GItem *)item;
- (NSString *)contents:(GItem *)item;
- (NSString *)cat:(GItem *)item;
- (NSString *)deps:(GItem *)item;
- (NSString *)dependents:(GItem *)item;

@end

@interface GSourceTransformer : NSValueTransformer
@end
