#import "GHomebrewCasks.h"
#import "GPackage.h"
#import "GAdditions.h"

@implementation GHomebrewCasks

+ (NSString *)prefix {
    return @"/usr/local";
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Homebrew Casks" agent:agent];
    if (self) {
        self.homepage = @"http://caskroom.io";
        self.cmd = [NSString stringWithFormat:@"%@/bin/brew cask", self.prefix];
    }
    return self;
}

- (NSArray *)list {
    
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"/bin/sh -c /usr/bin/grep__\"version__'\"__-r__/%@/Library/Taps/caskroom/homebrew-cask/Casks", self.prefix] split:@"\n"]];
    [output removeLastObject];
    [self.index removeAllObjects];
    [self.items removeAllObjects];
    NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    for (NSString *line in output) {
        NSArray *components = [[line stringByTrimmingCharactersInSet:whitespaceCharacterSet] split];
        NSString *name = [components[0] lastPathComponent];
        name = [name substringToIndex:[name length] -4];
        NSString *version = [components lastObject];
        version = [version substringWithRange:NSMakeRange(1, [version length]-2)];
        GPackage *pkg = [[GPackage alloc] initWithName:name
                                               version:version
                                                system:self
                                                status:GAvailableStatus];
        // avoid duplicate entries (i.e. aquamacs, opensesame)
        if (self[name] != nil) {
            GPackage *prevPackage = self[name];
            [self.items removeObjectIdenticalTo:prevPackage];
            if ([prevPackage.version compare:version] == NSOrderedDescending)
                pkg = prevPackage;
        }
        [self.items addObject:pkg];
        self[name] = pkg;
    }
    // TODO
    // output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ search \"\"", self.cmd] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    [self installed]; // update status
    return self.items;
}

// TODO: port from GHomebrew

- (NSArray *)installed {
    if (self.isHidden)
        return [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status != %@", @(GAvailableStatus)]];
    NSMutableArray *pkgs = [NSMutableArray array];
    if (self.mode == GOnlineMode)
        return pkgs;
    
    // TODO: remove inactive packages from items and allPackages
    
    GStatus status;
    for (GPackage *pkg in self.items) {
        status = pkg.status;
        pkg.installed = nil;
        if (status != GUpdatedStatus && status != GNewStatus)
            pkg.status = GAvailableStatus;
    }
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"/bin/sh -c export__PATH=%@/bin:$PATH__;__%@__list__2>/dev/null", self.prefix, [self.cmd stringByReplacingOccurrencesOfString:@" " withString:@"__"]] split:@"\n"]];
    [output removeLastObject];
    NSString *name;
    NSString *version;
    for (NSString *line in output) {
        name = line;
        if ([name is:@"Error:"])
            return pkgs;
        version = [[self outputFor:[NSString stringWithFormat:@"/bin/ls /opt/homebrew-cask/Caskroom/%@", name]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        // TODO: manage multiple versions
        version = [version stringByReplacingOccurrencesOfString:@"\n" withString:@", "];
        GPackage *pkg = self[name];
        NSString *latestVersion = (pkg == nil) ? nil : [pkg.version copy];
        if (pkg == nil) {
            pkg = [[GPackage alloc] initWithName:name
                                         version:latestVersion
                                          system:self
                                          status:GUpToDateStatus];
            self[name] = pkg;
        } else {
            if (pkg.status == GAvailableStatus) {
                pkg.status = GUpToDateStatus;
            }
        }
        pkg.installed = version; // TODO
        if (latestVersion != nil) {
            if (![version hasSuffix:latestVersion])
                pkg.status = GOutdatedStatus;
        }
        [pkgs addObject:pkg];
    }
    return pkgs;
}


- (NSArray *)outdated {
    if (self.isHidden)
        return [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status == %@", @(GOutdatedStatus)]];
    NSMutableArray *pkgs = [NSMutableArray array];
    for (GPackage *pkg in [self installed]) {
        if (pkg.status == GOutdatedStatus)
            [pkgs addObject:pkg];
    }
    return pkgs;
}

- (NSString *)info:(GItem *)item {
    if (!self.isHidden)
        return [self outputFor:@"/bin/sh -c export__PATH=%@/bin:$PATH__;__%@__info__%@", self.prefix, [self.cmd stringByReplacingOccurrencesOfString:@" " withString:@"__"], item.name];
    else
        return [super info:item];
}

- (NSString *)home:(GItem *)item {
    if (self.isHidden) {
        NSString *homepage;
        for (NSString *line in [[self cat:item] split:@"\n"]) {
            NSUInteger loc = [line index:@"homepage"];
            if (loc != NSNotFound) {
                homepage = [[line substringFromIndex:loc+8] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([homepage contains:@"http"])
                    return [homepage stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]];
            }
        }
    } else if (!self.isHidden && ((GPackage *)item).repo == nil)
        return [[self outputFor:@"/bin/sh -c export__PATH=%@/bin:$PATH__;__%@__info__%@", self.prefix, [self.cmd stringByReplacingOccurrencesOfString:@" " withString:@"__"], item.name] split:@"\n"][1];
    return [self log:item];
}

- (NSString *)log:(GItem *)item {
    if (item != nil ) {
        NSString *path;
        if (((GPackage *)item).repo == nil)
            path = @"caskroom/homebrew-cask/commits/master/Casks";
        //        else {
        //            NSArray *tokens = [((GPackage *)item).repo split:@"/"];
        //            NSString *user = tokens[0];
        //            path = [NSString stringWithFormat:@"%@/homebrew-%@/commits/master", user, tokens[1]];
        //            if ([user is:@"josegonzalez"])
        //            path = [path stringByAppendingString:@"/Formula"];
        //        }
        return [NSString stringWithFormat:@"http://github.com/%@/%@.rb", path, item.name];
    } else {
        return @"http://github.com/caskroom/homebrew-cask/commits";
    }
}

// TODO: port from GHomebrew

- (NSString *)contents:(GItem *)item {
    if (!self.isHidden)
        return [self outputFor:@"/bin/sh -c export__PATH=%@/bin:$PATH__;__%@__list__%@", self.prefix, [self.cmd stringByReplacingOccurrencesOfString:@" " withString:@"__"], item.name];
    else
        return @"";
}

- (NSString *)cat:(GItem *)item {
    if (!self.isHidden)
        return [self outputFor:@"/bin/sh -c export__PATH=%@/bin:$PATH__;__%@__cat__%@", self.prefix, [self.cmd stringByReplacingOccurrencesOfString:@" " withString:@"__"], item.name];
    // Doesn't work in RubyMotion:
    // return [self outputFor:@"/bin/sh -c export__PATH=%@/bin:$PATH__;__export__EDITOR=/bin/cat__;__%@__edit__%@", self.prefix, [self.cmd stringByReplacingOccurrencesOfString:@" " withString:@"__"], item.name];
    else
        return [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@_off/Library/Taps/caskroom/homebrew-cask/Casks/%@.rb", self.prefix, item.name] encoding:NSUTF8StringEncoding error:nil];
}

- (NSString *)deps:(GItem *)item {
    return @"";
}

- (NSString *)dependents:(GItem *)item {
    return @"";
}


- (NSArray *)availableCommands {
    return [super availableCommands];
}


- (NSString *) installCmd:(GPackage *)pkg {
    NSString *options = pkg.markedOptions;
    if (options == nil)
        options = @"";
    else
        options = [@"--" stringByAppendingString:[options stringByReplacingOccurrencesOfString:@" " withString:@" --"]];
    
    return [NSString stringWithFormat:@"%@ install %@ %@", self.cmd, options, pkg.name];
}

- (NSString *) uninstallCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ uninstall %@", self.cmd, pkg.name];
}

// FIXME: not possible currently
- (NSString *) upgradeCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ uninstall %@ ; %@ install %@", self.cmd, pkg.name, self.cmd, pkg.name ];
    
}

- (NSString *)cleanCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ cleanup --force %@ &>/dev/null", self.cmd, pkg.name];
}


//- (NSString *)updateCmd {
//    return [NSString stringWithFormat:@"%@ update", self.cmd];
//}

- (NSString *)hideCmd {
    return [NSString stringWithFormat:@"sudo mv %@ %@_off", self.prefix, self.prefix];
}

- (NSString *)unhideCmd {
    return [NSString stringWithFormat:@"sudo mv %@_off %@", self.prefix, self.prefix];
}

+ (NSString *)setupCmd {
    return [NSString stringWithFormat:@"%@/bin/brew install brew-cask ; %@/bin/brew cask list", self.prefix, self.prefix];
}

+ (NSString *)removeCmd {
    return [NSString stringWithFormat:@"%@/bin/brew untap caskroom/cask", self.prefix];
}

- (NSString *)verbosifiedCmd:(NSString *)cmd {
    NSMutableArray *tokens = [[cmd split] mutableCopy];
    [tokens insertObject:@"-v" atIndex:2];
    return [tokens join];
}

@end
