#import "GSystem.h"
#import "GAdditions.h"


@implementation GSystem

- (instancetype)initWithName:(NSString *)name agent:(GAgent *)agent {
    self = [super initWithName:name agent:agent];
    self.prefix = [[self class] prefix];
    self.status = GOnState;
    _index = [NSMutableDictionary dictionary];
    return self;
}

- (NSArray *)list {
    return @[];
}

- (NSArray *)installed {
    return @[];
}

- (NSArray *)outdated {
    return @[];
}

- (NSArray *)inactive {
    return @[];
}


+ (NSString *)prefix {
    return @"";
}

+ (NSArray *)list {
    return [[[self alloc] initWithAgent:[[GAgent alloc] init]] list];
}

+ (NSArray *)installed {
    return [(GSystem *)[[self alloc] initWithAgent:[[GAgent alloc] init]] installed];
}

+ (NSArray *)outdated {
    return [[[self alloc] initWithAgent:[[GAgent alloc] init]] outdated];
}

+ (NSArray *)inactive {
    return [[[self alloc] initWithAgent:[[GAgent alloc] init]] inactive];
}


- (BOOL)isHidden {
    return [[NSFileManager defaultManager] fileExistsAtPath:[[self prefix] stringByAppendingString:@"_off"]];
}

- (NSString *)keyForPackage:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@-%@", pkg.name, self.name];
}

- objectForKeyedSubscript:name {
    return self.index[[NSString stringWithFormat:@"%@-%@", name, self.name]];
}

- (void)setObject:pkg forKeyedSubscript:name {
    [self.index setObject:pkg forKeyedSubscript:[NSString stringWithFormat:@"%@-%@", name, self.name]];
}

- (NSArray *)categoriesList {
    NSMutableSet *cats = [NSMutableSet set];
    for (GItem *item in self.items) {
        [cats addObjectsFromArray:[item.categories split]];
    }
    return [[cats allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)dependenciesList:(GPackage *)pkg {
    return @[];
}

- (NSArray *)availableCommands { // TODO
    return @[
             @[@"help", @"CMD help"],
             @[@"man",  @"man CMD"]
             ];
}

- (NSString *)installCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ install %@", self.cmd, pkg.name];
}

- (NSString *)uninstallCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ uninstall %@", self.cmd, pkg.name];
}

- (NSString *)deactivateCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ deactivate %@", self.cmd, pkg.name];
}

- (NSString *)upgradeCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ upgrade %@", self.cmd, pkg.name];
}

- (NSString *)fetchCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ fetch %@", self.cmd, pkg.name];
}

- (NSString *)cleanCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ clean %@", self.cmd, pkg.name];
}


- (NSString *)options:(GPackage *)pkg {
    return nil;
}

- (NSString *)updateCmd {
    return nil;
}

- (NSString *)hideCmd {
    return nil;
}

- (NSString *)unhideCmd {
    return nil;
}

+ (NSString *)setupCmd {
    return nil;
}

+ (NSString *)removeCmd {
    return nil;
}

- (NSString *)outputFor:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *command = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return [self.agent outputForCommand:command];
}

- (NSString *)verbosifiedCmd:(NSString *)cmd {
    return [cmd stringByReplacingOccurrencesOfString:self.cmd withString:[NSString stringWithFormat:@"%@ -d", self.cmd]];
}

@end
