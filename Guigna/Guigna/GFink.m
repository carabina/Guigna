#import "GFink.h"
#import "GPackage.h"
#import "GAdditions.h"


@implementation GFink

+ (NSString *)prefix {
    return @"/sw";
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Fink" agent:agent];
    if (self) {
        self.homepage = @"http://www.finkproject.org";
        self.cmd = [NSString stringWithFormat:@"%@/bin/fink", self.prefix];
    }
    return self;
}

- (NSArray *)list {
    [self.index removeAllObjects];
    [self.items removeAllObjects];
    NSString *name;
    NSString *version;
    NSString *description;
    NSString *state;
    GStatus status;
    if (self.mode == GOnlineMode) {
        NSArray *nodes = [self.agent nodesForURL:@"http://pdb.finkproject.org/pdb/browse.php" XPath:@"//tr[@class=\"package\"]"];
        for (id node in nodes) {
            NSArray *dataRows = node[@"td"];
            description = [dataRows[2] stringValue];
            if ([description hasPrefix:@"[virtual"])
                continue;
            name = [dataRows[0] stringValue];
            version = [dataRows[1] stringValue];
            GPackage *pkg = [[GPackage alloc] initWithName:name
                                                   version:version
                                                    system:self
                                                    status:GAvailableStatus];
            pkg.description = description;
            [self.items addObject:pkg];
            self[name] = pkg;
        }
    } else {
        NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ list --tab", self.cmd] split:@"\n"]];
        [output removeLastObject];
        NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
        for (NSString *line in output) {
            NSArray *components = [line split:@"\t"];
            description = components[3];
            if ([description hasPrefix:@"[virtual"])
                continue;
            name = components[1];
            version = components[2];
            state = [components[0] stringByTrimmingCharactersInSet:whitespaceCharacterSet];
            status = GAvailableStatus;
            if ([state is:@"i"] || [state is:@"p"])
                status = GUpToDateStatus;
            else if ([state is:@"(i)"])
                status = GOutdatedStatus;
            GPackage *pkg = [[GPackage alloc] initWithName:name
                                                   version:version
                                                    system:self
                                                    status:status];
            pkg.description = description;
            [self.items addObject:pkg];
            self[name] = pkg;
        }
    }
    [self installed]; // update installed pkgs index
    return self.items;
}


- (NSArray *)installed {
    if (self.isHidden)
        return [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status != %@", @(GAvailableStatus)]];
    NSMutableArray *pkgs = [NSMutableArray array];
    if (self.mode == GOnlineMode)
        return pkgs;
    NSString *name;
    NSString *version;
    GStatus status;
    for (GPackage *pkg in self.items) {
        status = pkg.status;
        pkg.installed = nil;
        if (status != GUpdatedStatus && status != GNewStatus) // TODO: ![pkg.description hasPrefix:@"[virtual"])
            pkg.status = GAvailableStatus;
    }
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@/bin/dpkg-query --show", self.prefix] split:@"\n"]];
    [output removeLastObject];
    for (NSString *line in output) {
        NSArray *components = [line split:@"\t"];
        name = components[0];
        version = components[1];
        status = GUpToDateStatus;
        GPackage *pkg = self[name];
        NSString *latestVersion = (pkg == nil) ? nil : [pkg.version copy];
        if (pkg == nil) {
            pkg = [[GPackage alloc] initWithName:name
                                         version:latestVersion
                                          system:self
                                          status:status];
            self[name] = pkg;
        } else {
            if (pkg.status == GAvailableStatus)
                pkg.status = status;
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
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ list --outdated --tab", self.cmd] split:@"\n"]];
    [output removeLastObject];
    NSString *name;
    NSString *version;
    NSString *description;
    for (NSString *line in output) {
        NSArray *components = [line split:@"\t"];
        name = components[1];
        version = components[2];
        description = components[3];
        GPackage *pkg = self[name];
        if (pkg == nil) {
            pkg = [[GPackage alloc] initWithName:name
                                         version:version
                                          system:self
                                          status:GOutdatedStatus];
            self[name] = pkg;
        } else
            pkg.status = GOutdatedStatus;
        pkg.description = description;
        [pkgs addObject:pkg];
    }
    return pkgs;
}

// TODO: parse all divs (section, maintainer, ...)
- (NSString *)info:(GItem *)item {
    if (self.isHidden)
        return [super info:item];
    if (self.mode == GOnlineMode) {
        NSArray *nodes = [self.agent nodesForURL:[NSString stringWithFormat: @"http://pdb.finkproject.org/pdb/package.php/%@", item.name] XPath:@"//div[@class=\"desc\"]"];
        if ([nodes count] == 0)
            return @"Info not available]";
        else {
            NSString *desc = [nodes[0] stringValue];
            return desc;
        }
    } else {
        return [self outputFor:@"%@ dumpinfo %@", self.cmd, item.name];
    }
}

- (NSString *)home:(GItem *)item {
    NSArray *nodes = [self.agent nodesForURL:[NSString stringWithFormat: @"http://pdb.finkproject.org/pdb/package.php/%@", item.name] XPath:@"//a[contains(@title, \"home\")]"];
    if ([nodes count] == 0)
        return @"[Homepage not available]";
    else {
        NSString *homepage = [nodes[0] stringValue];
        return homepage;
    }
}

- (NSString *)log:(GItem *)item {
    if (item != nil)
        return [NSString stringWithFormat: @"http://pdb.finkproject.org/pdb/package.php/%@", item.name];
    else
        return @"http://www.finkproject.org/package-updates.php";
    // @"http://github.com/fink/fink/commits/master"
}

- (NSString *)contents:(GItem *)item {
    return @"";
}

- (NSString *)cat:(GItem *)item {
    if (self.isHidden || self.mode == GOnlineMode) {
        NSArray *nodes = [self.agent nodesForURL:[NSString stringWithFormat: @"http://pdb.finkproject.org/pdb/package.php/%@", item.name] XPath:@"//a[contains(@title, \"info\")]"];
        if ([nodes count] == 0)
            return @"[.info not reachable]";
        else {
            NSString *cvs = [nodes[0] stringValue];
            NSString *info = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat: @"http://fink.cvs.sourceforge.net/fink/%@", cvs]] encoding:NSUTF8StringEncoding error:nil];
            return info;
        }
    } else {
        return [self outputFor:@"%@ dumpinfo %@", self.cmd, item.name];
    }
}


- (NSString *) installCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"sudo %@ install %@", self.cmd, pkg.name];
}

- (NSString *) uninstallCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"sudo %@ remove %@", self.cmd, pkg.name];
}

- (NSString *) upgradeCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"sudo %@ update %@", self.cmd, pkg.name];
}


- (NSString *)updateCmd {
    if (self.mode == GOnlineMode)
        return nil;
    else
        return [NSString stringWithFormat:@"sudo %@ selfupdate", self.cmd];
}

- (NSString *)hideCmd {
    return [NSString stringWithFormat:@"sudo mv %@ %@_off", self.prefix, self.prefix];
}

- (NSString *)unhideCmd {
    return [NSString stringWithFormat:@"sudo mv %@_off %@", self.prefix, self.prefix];
}


+ (NSString *)setupCmd {
    return @"sudo mv /usr/local /usr/local_off ; sudo mv /opt/local /opt/local_off ; sudo mv /usr/pkg /usr/pkg_off ; cd ~/Library/Application\\ Support/Guigna/Fink ; curl -L -O http://downloads.sourceforge.net/fink/fink-0.37.0.tar.gz ; tar -xvzf fink-0.37.0.tar.gz ; cd fink-0.37.0 ; sudo ./bootstrap ; /sw/bin/pathsetup.sh ; . /sw/bin/init.sh ; /sw/bin/fink selfupdate-rsync ; /sw/bin/fink index -f ; sudo mv /usr/local_off /usr/local ; sudo mv /opt/local_off /opt/local ; sudo mv /usr/pkg_off /usr/pkg";
}

+ (NSString *)removeCmd {
    return @"sudo rm -rf /sw";
}

- (NSString *)verbosifiedCmd:(NSString *)cmd {
    return [cmd stringByReplacingOccurrencesOfString:self.cmd withString:[NSString stringWithFormat:@"%@ -v", self.cmd]];
}

@end
