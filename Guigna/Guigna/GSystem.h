#import "GSource.h"

#import "GAgent.h"
#import "GPackage.h"

@interface GSystem : GSource

@property(strong) NSString *prefix;
@property(strong) NSMutableDictionary *index;
@property(readonly, getter=isHidden) BOOL hidden;

- (instancetype)initWithName:(NSString *)name agent:(GAgent *)agent;

- (NSArray *)list;
- (NSArray *)installed;
- (NSArray *)outdated;
- (NSArray *)inactive;

+ (NSString *)prefix;
+ (NSArray *)list;
+ (NSArray *)installed;
+ (NSArray *)outdated;
+ (NSArray *)inactive;

- (BOOL)isHidden;
- (NSString *)keyForPackage:(GPackage *)pkg;
- objectForKeyedSubscript:name;
- (void)setObject:pkg forKeyedSubscript:name;

- (NSArray *)categoriesList;
- (NSArray *)availableCommands;
- (NSArray *)dependenciesList:(GPackage *)pkg;
- (NSString *)options:(GPackage *)pkg;
- (NSString *)installCmd:(GPackage *)pkg;
- (NSString *)uninstallCmd:(GPackage *)pkg;
- (NSString *)deactivateCmd:(GPackage *)pkg;
- (NSString *)upgradeCmd:(GPackage *)pkg;
- (NSString *)fetchCmd:(GPackage *)pkg;
- (NSString *)cleanCmd:(GPackage *)pkg;
- (NSString *)updateCmd;
- (NSString *)hideCmd;
- (NSString *)unhideCmd;

+ (NSString *)setupCmd;
+ (NSString *)removeCmd;

- (NSString *)outputFor:(NSString *)format, ...;
- (NSString *)verbosifiedCmd:(NSString *)cmd;

@end
