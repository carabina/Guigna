#import "GPackage.h"
#import "GSystem.h"

@implementation GPackage

- (instancetype)initWithName:(NSString *)name
           version:(NSString *)version
            system:(GSystem *)system
            status:(GStatus)status {
    self = [super initWithName:name
            version:version
            source:(GSource *)system
            status:status];
    self.system = system;
    return self;
}

- (NSString *)key {
    return [self.system keyForPackage:self];  
}

- (NSArray *)dependenciesList {
    return [self.system dependenciesList:self];
}

- (NSString *)installCmd {
    return [self.system installCmd:self];
}


- (NSString *)uninstallCmd {
    return [self.system uninstallCmd:self];
}


- (NSString *)deactivateCmd {
    return [self.system deactivateCmd:self];
}


- (NSString *)upgradeCmd {
    return [self.system upgradeCmd:self];
}


- (NSString *)fetchCmd {
    return [self.system fetchCmd:self];
}


- (NSString *)cleanCmd {
    return [self.system cleanCmd:self];
}


@end
