#import "GMacPorts.h"
#import "GPackage.h"
#import "GAdditions.h"

@implementation GMacPorts

+ (NSString *)prefix {
    return @"/opt/local";
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"MacPorts" agent:agent];
    if (self) {
        self.homepage = @"http://www.macports.org";
        self.cmd = [NSString stringWithFormat:@"%@/bin/port", self.prefix];
    }
    return self;
}

- (NSArray *)list {
    [self.index removeAllObjects];
    [self.items removeAllObjects];
    NSMutableArray *pkgs = [NSMutableArray array];
    if ([self.agent.appDelegate.defaults[@"MacPortsParsePortIndex"] isEqual:@NO]) {
        NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ list", self.cmd] split:@"\n"]];
        [output removeLastObject];
        NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
        NSString *name;
        NSString *version;
        // NSString *revision;
        NSString *categories;
        for (NSString *line in output) {
            NSArray *components = [line split:@"@"];
            name = [components[0] stringByTrimmingCharactersInSet:whitespaceCharacterSet];
            components = [components[1] split];
            version = components[0];
            // revision = "..."
            categories = [[components lastObject] split:@"/"][0];
            GPackage *pkg = [[GPackage alloc] initWithName:name
                                                   version:version
                                                    system:self
                                                    status:GAvailableStatus];
            //            GPackage *pkg = [[GPackage alloc] initWithName:name
            //                                                   version:[NSString stringWithFormat:@"%@_%@", version, revision]
            //                                                    system:self
            //                                                    status:GAvailableStatus];
            pkg.categories = categories;
            // pkg.description = description;
            // pkg.license = license;
            // if (self.mode == GOnlineMode) {
            //     pkg.homepage = homepage;
            // }
            [pkgs addObject:pkg];
            [self.items addObject:pkg];
            self[name] = pkg;
            
        }
    } else {
        NSString *portIndex;
        if (self.mode == GOnlineMode) // TODO: fetch PortIndex
            portIndex = [NSString stringWithContentsOfFile:[@"~/Library/Application Support/Guigna/MacPorts/PortIndex" stringByExpandingTildeInPath] encoding:NSUTF8StringEncoding error:nil];
        else
            portIndex = [NSString stringWithContentsOfFile:[self.prefix stringByAppendingString:@"/var/macports/sources/rsync.macports.org/release/tarballs/ports/PortIndex"] encoding:NSUTF8StringEncoding error:nil];
        NSScanner *s =  [NSScanner scannerWithString:portIndex];
        [s setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
        NSMutableCharacterSet *endsCharaterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [endsCharaterSet addCharactersInString:@"}"];
        NSString *str = [[NSString alloc] init];
        NSUInteger loc;
        NSString *name = [[NSString alloc] init];
        NSString *key =  [[NSString alloc] init];
        NSMutableString *value =  [[NSMutableString alloc] init];
        NSString *version = nil;
        NSString *revision = nil;
        NSString *categories = nil;
        NSString *description = nil;
        NSString *homepage = nil;
        NSString *license = nil;
        while (1) {
            if ( ![s scanUpToString:@" " intoString: &name])
                break;
            [s scanUpToString:@"\n" intoString: nil];
            [s scanString:@"\n" intoString: nil];
            while (1) {
                [s scanUpToString:@" " intoString: &key];
                [s scanString:@" " intoString: nil];
                [s scanUpToCharactersFromSet:endsCharaterSet intoString:&str];
                [value setString:str];
                NSRange range = [value rangeOfString:@"{"];
                while (range.location != NSNotFound) {
                    [value replaceCharactersInRange:range withString:@""];
                    if ([s scanUpToString:@"}" intoString:&str])
                        [value appendString:str];
                    [s scanString:@"}" intoString:nil];
                    range = [value rangeOfString:@"{"];
                }
                if ([key is:@"version"])
                    version = [value copy];
                else if ([key is:@"revision"])
                    revision = [value copy];
                else if ([key is:@"categories"])
                    categories = [value copy];
                else if ([key is:@"description"])
                    description = [value copy];
                else if ([key is:@"homepage"])
                    homepage = [value copy];
                else if ([key is:@"license"])
                    license = [value copy];
                loc = [s scanLocation];
                if ([s scanString:@"\n" intoString:nil]) {
                    break;
                }
                [s scanString:@" " intoString: nil];
            }
            GPackage *pkg = [[GPackage alloc] initWithName:name
                                                   version:[NSString stringWithFormat:@"%@_%@", version, revision]
                                                    system:self
                                                    status:GAvailableStatus];
            pkg.categories = categories;
            pkg.description = description;
            pkg.license = license;
            if (self.mode == GOnlineMode) {
                pkg.homepage = homepage;
            }
            [pkgs addObject:pkg];
            [self.items addObject:pkg];
            self[name] = pkg;
        }
    }
    [self installed]; // update status
    return pkgs;
}


- (NSArray *)installed {
    if (self.isHidden)
        return [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status != %@", @(GAvailableStatus)]];
    NSMutableArray *pkgs = [NSMutableArray array];
    if (self.mode == GOnlineMode)
        return pkgs;
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ installed", self.cmd] split:@"\n"]];
    [output removeLastObject];
    [output removeObjectAtIndex:0];
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
    [self outdated]; // index outdated ports
    NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    NSString *name;
    NSString *version;
    NSString *variants;
    for (NSString *line in output) {
        NSArray *components = [[line stringByTrimmingCharactersInSet:whitespaceCharacterSet] split];
        name = components[0];
        version = [components[1] substringFromIndex:1];
        variants = nil;
        NSUInteger sep = [version rangeOfString:@"+"].location;
        if (sep != NSNotFound) {
            variants = [[[version substringFromIndex:sep +1] split:@"+"] join];
            version = [version substringToIndex:sep];
        }
        if (variants != nil)
            version = [NSString stringWithFormat:@"%@ +%@", version, [variants stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
        status = [components count] == 2 ? GInactiveStatus : GUpToDateStatus;
        GPackage *pkg = self[name];
        NSString *latestVersion = (pkg == nil) ? nil : [pkg.version copy];
        if (status == GInactiveStatus)
            pkg = nil;
        if (pkg == nil) {
            pkg = [[GPackage alloc] initWithName:name
                                         version:latestVersion
                                          system:self
                                          status:status];
            if (status != GInactiveStatus)
                self[name] = pkg;
            else {
                [self.items addObject:pkg];
                [self.agent.appDelegate.allPackages addObject:pkg]; // TODO: ugly
            }
        } else {
            if (pkg.status == GAvailableStatus)
                pkg.status = status;
        }
        pkg.installed = version;
        pkg.options = variants;
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
    [output removeObjectAtIndex:0];
    for (NSString *line in output) {
        NSArray *components = [[line split:@" < "][0] split];
        NSString *name = components[0];
        NSString *version = [components lastObject];
        GPackage *pkg = self[name];
        NSString *latestVersion = (pkg == nil) ? nil : [pkg.version copy];
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


- (NSArray *)availableCommands {
    return @[@"sudo install -y"];
}


- (NSString *)info:(GItem *)item {
    if (self.isHidden)
        return [super info:item];
    if (self.mode == GOnlineMode) {
        // TODO: format keys and values
        NSString *info = [[self.agent nodesForURL:[NSString stringWithFormat:@"http://www.macports.org/ports.php?by=name&substr=%@", item.name] XPath:@"//div[@id=\"content\"]/dl"][0] stringValue];
        NSArray *keys = [self.agent nodesForURL:[NSString stringWithFormat:@"http://www.macports.org/ports.php?by=name&substr=%@", item.name] XPath:@"//div[@id=\"content\"]/dl//i"];
        NSString *stringValue;
        for (id key in keys) {
            stringValue = [key stringValue];
            info = [info stringByReplacingOccurrencesOfString:stringValue withString:[NSString stringWithFormat:@"\n\n%@\n", stringValue]];
        }
        return info;
    }
    NSInteger columns = [self.agent.appDelegate shellColumns];
    return [self outputFor:@"/bin/sh -c export__COLUMNS=%ld__;__%@__info__%@", columns, self.cmd, item.name];
}

- (NSString *)home:(GItem *)item {
    if (self.isHidden) {
        NSString *homepage;
        for (NSString *line in [[self cat:item] split:@"\n"]) {
            if ([line contains:@"homepage"]) {
                homepage = [[line substringFromIndex:8] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([homepage hasPrefix:@"http"])
                    return homepage;
            }
        }
        return [self log:item];
    }
    if (self.mode == GOnlineMode)
        return item.homepage;
    NSString *output = [self outputFor:@"%@ -q info --homepage %@", self.cmd, item.name];
    return [output substringToIndex:[output length]-1];
}

- (NSString *)log:(GItem *)item {
    if (item != nil ) {
        NSString *category = [item.categories split][0];
        return [NSString stringWithFormat:@"http://trac.macports.org/log/trunk/dports/%@/%@/Portfile", category, item.name];
    } else {
        return @"http://trac.macports.org/timeline";
    }
}

- (NSString *)contents:(GItem *)item {
    if (self.isHidden || self.mode == GOnlineMode)
        return @"[Not available]"; // TODO
    return [self outputFor:@"%@ contents %@", self.cmd, item.name];
}

- (NSString *)cat:(GItem *)item {
    if (self.isHidden || self.mode == GOnlineMode)
        return [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://trac.macports.org/browser/trunk/dports/%@/%@/Portfile?format=txt", [item.categories split][0], item.name]] encoding:NSUTF8StringEncoding error:nil];
    return [self outputFor:@"%@ cat %@", self.cmd, item.name];
}

- (NSString *)deps:(GItem *)item {
    if (self.isHidden || self.mode == GOnlineMode)
        return @"[Cannot compute the dependencies now]"; // TODO
    return [self outputFor:@"%@ rdeps --index %@", self.cmd, item.name];
}

- (NSString *)dependents:(GItem *)item {
    if (self.isHidden || self.mode == GOnlineMode)
        return @"";
    // TODO only when status == installed
    if (item.status != GAvailableStatus)
        return [self outputFor:@"%@ dependents %@", self.cmd, item.name];
    else
        return [NSString stringWithFormat:@"[%@ not installed]", item.name];
}


- (NSArray *)dependenciesList:(GPackage *)pkg { // TODO
    NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ rdeps --index %@", self.cmd, pkg.name] split:@"\n"]];
    [output removeLastObject];
    [output removeObjectAtIndex:0];
    NSMutableArray *deps = [NSMutableArray array];
    for (NSString *line in output) {
        [deps addObject:[line stringByTrimmingCharactersInSet:whitespaceCharacterSet]];
    }
    return deps;
}

- (NSString *)options:(GPackage *)pkg {
    NSString *variants;
    NSString *output = [[self outputFor:[NSString stringWithFormat:@"%@ info --variants %@", self.cmd, pkg.name]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([output length] > 10 ) {
        variants = [[[output substringFromIndex:10] split:@", "] join];
    }
    return variants;
}


- (NSString *)installCmd:(GPackage *)pkg {
    NSString *variants = pkg.markedOptions;
    if (variants == nil)
        variants = @"";
    else
        variants = [@"+" stringByAppendingString:[variants stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
    return [NSString stringWithFormat:@"sudo %@ install %@ %@", self.cmd, pkg.name, variants];
}

- (NSString *)uninstallCmd:(GPackage *)pkg {
    if (pkg.status == GOutdatedStatus || pkg.status == GUpdatedStatus)
        return [NSString stringWithFormat:@"sudo %@ -f uninstall %@ ; sudo %@ clean --all %@", self.cmd, pkg.name, self.cmd, pkg.name];
    else
        return [NSString stringWithFormat:@"sudo %@ -f uninstall %@ @%@", self.cmd, pkg.name, pkg.installed];
}

- (NSString *)deactivateCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"sudo %@ deactivate %@", self.cmd, pkg.name];
}

- (NSString *)upgradeCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"sudo %@ upgrade %@", self.cmd, pkg.name];
    //    return [NSString stringWithFormat:@"sudo %@ -f uninstall %@ ; sudo %@ -f clean --all %@ ; sudo %@ install %@", self.cmd, pkg.name, self.cmd, pkg.name, self.cmd, pkg.name] ;
}

- (NSString *)fetchCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"sudo %@ fetch %@", self.cmd, pkg.name];
}

- (NSString *)cleanCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"sudo %@ clean --all %@", self.cmd, pkg.name];
}

- (NSString *)updateCmd {
    if (self.mode == GOnlineMode) {
        return @"sudo cd ; cd ~/Library/Application\\ Support/Guigna/Macports ; /usr/bin/rsync -rtzv rsync://rsync.macports.org/release/tarballs/PortIndex_darwin_13_i386/PortIndex PortIndex";
    } else {
        return [NSString stringWithFormat:@"sudo %@ -d selfupdate", self.cmd];
    }
}

- (NSString *)hideCmd {
    return [NSString stringWithFormat:@"sudo mv %@ %@_off", self.prefix, self.prefix];
}

- (NSString *)unhideCmd {
    return [NSString stringWithFormat:@"sudo mv %@_off %@", self.prefix, self.prefix];
}


@end
