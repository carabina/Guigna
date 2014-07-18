#import "GItem.h"

@interface GPackage : GItem

@property(strong) NSString *options;
@property(strong) NSString *markedOptions;
@property(strong) NSString *repo;

- (instancetype)initWithName:(NSString *)name
           version:(NSString *)version
            system:(GSystem *)system
            status:(GStatus)status;

- (NSString *) key;
- (NSArray *)dependenciesList;
- (NSString *)installCmd;
- (NSString *)uninstallCmd;
- (NSString *)deactivateCmd;
- (NSString *)upgradeCmd;
- (NSString *)fetchCmd;
- (NSString *)cleanCmd;

@end
