#import "GHomebrew.h"
#import "GPackage.h"
#import "GAdditions.h"

@implementation GHomebrew

+ (NSString *)prefix {
    return @"/usr/local";
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Homebrew" agent:agent];
    if (self) {
        self.homepage = @"http://brew.sh/";
        self.cmd = [NSString stringWithFormat:@"%@/bin/brew", self.prefix];
    }
    return self;
}

- (NSArray *)list {
    [self.index removeAllObjects];
    [self.items removeAllObjects];
    
    // /usr/bin/ruby -C /usr/local/Library/Homebrew -I. -e "require 'global'; require 'formula'; Formula.each {|f| puts \"#{f.name} #{f.pkg_version}\"}"
    
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"/usr/bin/ruby -C %@/Library/Homebrew -I. -e require__'global';require__'formula';__Formula.each__{|f|__puts__\"#{f.name}__#{f.pkg_version}__#{f.bottle}\"}", self.prefix] split:@"\n"]];
    [output removeLastObject];
    for (NSString *line in output) {
        NSArray *components = [line split];
        NSString *name = components[0];
        NSString *bottle = components[2];
        GPackage *pkg = [[GPackage alloc] initWithName:name
                                               version:components[1]
                                                system:self
                                                status:GAvailableStatus];
        if (![bottle is:@""])
            pkg.description = @"Bottle";
        [self.items addObject:pkg];
        self[name] = pkg;
    }
    // TODO
    if ([self.agent.appDelegate.defaults[@"HomebrewMainTaps"] isEqual:@YES]) {
        output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ search \"\"", self.cmd] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        for (NSString *line in output) {
            if (![line contains:@"/"])
                continue;
            NSArray *tokens = [line split:@"/"];
            NSString *name = tokens[[tokens count]-1];
            NSString *repo = [NSString stringWithFormat:@"%@/%@", tokens[0], tokens[1]];
            GPackage *pkg = [[GPackage alloc] initWithName:name
                                                   version:@""
                                                    system:self
                                                    status:GAvailableStatus];
            pkg.categories = tokens[1];
            pkg.repo = repo;
            pkg.description = repo;
            [self.items addObject:pkg];
            self[name] = pkg;
        }
    }
    [self installed]; // update status
    return self.items;
}


- (NSArray *)installed {
    if (self.isHidden)
        return [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status != %@", @(GAvailableStatus)]];
    NSMutableArray *pkgs = [NSMutableArray array];
    if (self.mode == GOnlineMode)
        return pkgs;
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ list --versions", self.cmd] split:@"\n"]];
    [output removeLastObject];
    GStatus status;
    NSArray *inactive = [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status == %@", @(GInactiveStatus)]];
    [self.items removeObjectsInArray:inactive];
    [self.agent.appDelegate.allPackages removeObjectsInArray:inactive]; // TODO: ugly
    for (GPackage *pkg in self.items) {
        status = pkg.status;
        pkg.installed = nil;
        if (status != GUpdatedStatus && status != GNewStatus)
            pkg.status = GAvailableStatus;
    }
    [self outdated]; // update status
    NSString *name;
    NSString *version;
    for (NSString *line in output) {
        NSMutableArray *components = [[line split] mutableCopy];
        name = components[0];
        if ([name is:@"Error:"])
            return pkgs;
        [components removeObjectAtIndex:0];
        NSUInteger versionCount = [components count];
        version = [components lastObject];
        GPackage *pkg = self[name];
        NSString *latestVersion = (pkg == nil) ? nil : [pkg.version copy];
        if (versionCount > 1) {
            for (NSInteger i = 0; i < versionCount - 1; i++) {
                GPackage *inactivePkg = [[GPackage alloc] initWithName:name
                                                               version:latestVersion
                                                                system:self
                                                                status:GInactiveStatus];
                inactivePkg.installed = components[i];
                [self.items addObject:inactivePkg];
                [self.agent.appDelegate.allPackages addObject:inactivePkg]; // TODO: ugly
                [pkgs addObject:inactivePkg];
            }
        }
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
        pkg.installed = version;
        [pkgs addObject:pkg];
    }
    return pkgs;
}

- (NSArray *)outdated {
    if (self.isHidden)
        return [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status == %@", @(GOutdatedStatus)]];
    NSMutableArray *pkgs = [NSMutableArray array];
    if (self.mode == GOnlineMode)
        return pkgs;
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ outdated", self.cmd] split:@"\n"]];
    [output removeLastObject];
    for (NSString *line in output) {
        NSArray *components = [line split];
        NSString *name = components[0];
        if ([name is:@"Error:"])
            return pkgs;
        GPackage *pkg = self[name];
        NSString *latestVersion = (pkg == nil) ? nil : [pkg.version copy];
        // NSString *version = components[1]; // TODO: strangely, output contains only name
        NSString *version = (pkg == nil) ? @"..." : [pkg.installed copy];
        if (pkg == nil) {
            pkg = [[GPackage alloc] initWithName:name
                                         version:latestVersion
                                          system:self
                                          status:GOutdatedStatus];
            self[name] = pkg;
        } else
            pkg.status = GOutdatedStatus;
        pkg.installed = version;
        [pkgs addObject:pkg];
    }
    return pkgs;
}

- (NSArray *)inactive {
    if (self.isHidden)
        return [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status == %@", @(GInactiveStatus)]];
    NSMutableArray *pkgs = [NSMutableArray array];
    if (self.mode == GOnlineMode)
        return pkgs;
    for (GPackage *pkg in [self installed]) {
        if (pkg.status == GInactiveStatus)
            [pkgs addObject:pkg];
    }
    return pkgs;
}


- (NSString *)info:(GItem *)item {
    if (!self.isHidden)
        return [self outputFor:@"%@ info %@", self.cmd, item.name];
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
        return [[self outputFor:@"%@ info %@", self.cmd, item.name] split:@"\n"][1];
    return [self log:item];
}

- (NSString *)log:(GItem *)item {
    if (item != nil ) {
        NSString *path;
        if (((GPackage *)item).repo == nil)
            path = @"Homebrew/homebrew/commits/master/Library/Formula";
        else {
            NSArray *tokens = [((GPackage *)item).repo split:@"/"];
            NSString *user = tokens[0];
            path = [NSString stringWithFormat:@"%@/homebrew-%@/commits/master", user, tokens[1]];
            if ([user is:@"josegonzalez"])
                path = [path stringByAppendingString:@"/Formula"];
        }
        return [NSString stringWithFormat:@"http://github.com/%@/%@.rb", path, item.name];
    } else {
        return @"http://github.com/Homebrew/homebrew/commits";
    }
}

- (NSString *)contents:(GItem *)item {
    if (!self.isHidden)
        return [self outputFor:@"%@ list -v %@", self.cmd, item.name];
    else
        return @"";
}

- (NSString *)cat:(GItem *)item {
    if (!self.isHidden)
        return [self outputFor:@"%@ cat %@", self.cmd, item.name];
    else {
        return [NSString stringWithContentsOfFile:[self.prefix stringByAppendingFormat:@"_off/Library/Formula/%@.rb", item.name] encoding:NSUTF8StringEncoding error: nil];
    }
}

- (NSString *)deps:(GItem *)item {
    if (!self.isHidden)
        return [self outputFor:@"%@ deps -n %@", self.cmd, item.name];
    else
        return @"[Cannot compute the dependencies now]";
}

- (NSString *)dependents:(GItem *)item {
    if (!self.isHidden)
        return [self outputFor:@"%@ uses --installed %@", self.cmd, item.name];
    else
        return @"";
}

- (NSString *)options:(GPackage *)pkg {
    NSString *options = nil;
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:[NSString stringWithFormat:@"%@ options %@", self.cmd, pkg.name]] split:@"\n"]];
    if ([output count] > 1 ) {
        NSArray * optionLines = [output filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH '--'"]];
        options = [[optionLines join] stringByReplacingOccurrencesOfString:@"--" withString:@""];
    }
    return options;
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
    if (pkg.status == GInactiveStatus)
        return [self cleanCmd:pkg];
    else  // TODO: manage --force flag
        return [NSString stringWithFormat:@"%@ remove --force %@", self.cmd, pkg.name];
}

- (NSString *) upgradeCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ upgrade %@", self.cmd, pkg.name];
    
}

- (NSString *)cleanCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"%@ cleanup --force %@ &>/dev/null ; rm -f /Library/Caches/Homebrew/%@-%@*bottle*", self.cmd, pkg.name, pkg.name, pkg.version];
}

- (NSString *)updateCmd {
    return [NSString stringWithFormat:@"%@ update", self.cmd];
}

- (NSString *)hideCmd {
    return [NSString stringWithFormat:@"sudo mv %@ %@_off", self.prefix, self.prefix];
}

- (NSString *)unhideCmd {
    return [NSString stringWithFormat:@"sudo mv %@_off %@", self.prefix, self.prefix];
}

+ (NSString *)setupCmd {
    return @"ruby -e \"$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)\" ; /usr/local/bin/brew update";
}

+ (NSString *)removeCmd {
    return @"cd /usr/local ; curl -L https://raw.github.com/gist/1173223 -o uninstall_homebrew.sh; sudo sh uninstall_homebrew.sh ; rm uninstall_homebrew.sh ; sudo rm -rf /Library/Caches/Homebrew; rm -rf /usr/local/.git";
}

- (NSString *)verbosifiedCmd:(NSString *)cmd {
    NSMutableArray *tokens = [[cmd split] mutableCopy];
    [tokens insertObject:@"-v" atIndex:2];
    return [tokens join];
}

@end
