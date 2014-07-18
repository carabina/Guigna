#import "GPkgsrc.h"
#import "GPackage.h"
#import "GAdditions.h"


@implementation GPkgsrc

+ (NSString *)prefix {
    return @"/usr/pkg";
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"pkgsrc" agent:agent];
    if (self) {
        self.homepage = @"http://www.pkgsrc.org";
        self.cmd = [NSString stringWithFormat:@"%@/sbin/pkg_info", self.prefix];
    }
    return self;
}


// include category for managing duplicates of xp, binutils, fuse, p5-Net-CUPS
- (NSString *)keyForPackage:(GPackage *)pkg {
    if (pkg.ID != nil)
        return [NSString stringWithFormat:@"%@-%@", pkg.ID, self.name];
    else {
        return [NSString stringWithFormat:@"%@/%@-%@", [pkg.categories split][0], pkg.name, self.name];
    }
}

- (NSArray *)list {
    [self.index removeAllObjects];
    [self.items removeAllObjects];
    NSString *indexPath = [@"~/Library/Application Support/Guigna/pkgsrc/INDEX" stringByExpandingTildeInPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:indexPath]) {
        NSArray *lines = [[NSString stringWithContentsOfFile:indexPath encoding:NSUTF8StringEncoding error:nil]split:@"\n"];
        for (NSString *line in lines) {
            NSArray *components = [line split:@"|"];
            NSString *name = components[0];
            NSUInteger sep = [name rangeOfString:@"-" options:NSBackwardsSearch].location;
            if (sep == NSNotFound)
                continue;
            NSString *version = [name substringFromIndex:sep+1];
            // name = [name substringToIndex:sep];
            NSString *ID = components[1];
            sep = [ID rangeOfString:@"/" options:NSBackwardsSearch].location;
            name = [ID substringFromIndex:sep+1];
            NSString *description = components[3];
            NSString *category = components[6];
            NSString *homepage = components[11];
            GPackage *pkg = [[GPackage alloc] initWithName:name
                                                       version:version
                                                        system:self
                                                        status:GAvailableStatus];
            pkg.ID = ID;
            pkg.categories = category;
            pkg.description = description;
            pkg.homepage = homepage;
            [self.items addObject:pkg];
            self[ID] = pkg;
        }
    } else {
        NSArray *nodes = [self.agent nodesForURL:@"http://ftp.netbsd.org/pub/pkgsrc/current/pkgsrc/README-all.html" XPath:@"//tr"];
        for (id node in nodes) {
            NSArray *rowData = node[@"td"];
            if ([rowData count] == 0)
                continue;
            NSString *name = [rowData[0] stringValue];
            NSUInteger sep = [name rangeOfString:@"-" options:NSBackwardsSearch].location;
            if (sep == NSNotFound)
                continue;
            NSString *version = [name substringWithRange:NSMakeRange(sep+1, [name length]-sep-3)];
            name = [name substringToIndex:sep];
            NSString *category = [rowData[1] stringValue];
            category = [category substringWithRange:NSMakeRange(1, [category length]-3)];
            NSString *description = [rowData[2] stringValue];
            sep = [description rangeOfString:@"  " options:NSBackwardsSearch].location;
            if (sep != NSNotFound)
                description = [description substringToIndex:sep];
            GPackage *pkg = [[GPackage alloc] initWithName:name
                                                       version:version
                                                        system:self
                                                        status:GAvailableStatus];
            pkg.categories = category;
            pkg.description = description;
            NSString *ID = [NSString stringWithFormat:@"%@/%@", category, name];
            pkg.ID = ID;
            [self.items addObject:pkg];
            self[ID] = pkg;
        }
    }
    [self installed]; // update installed pkgs index
    return self.items;
}

// TODO: outdated
- (NSArray *)installed {
    if (self.isHidden)
        return [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status != %@", @(GAvailableStatus)]];
    NSMutableArray *pkgs = [NSMutableArray array];
    if (self.mode == GOnlineMode)
        return pkgs;
    GStatus status;
    for (GPackage *pkg in self.items) {
        status = pkg.status;
        pkg.installed = nil;
        if (status != GUpdatedStatus && status != GNewStatus)
            pkg.status = GAvailableStatus;
    }
    // [self outdated]; // index outdated ports // TODO
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@", self.cmd] split:@"\n"]];
    NSMutableArray *ids = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ -Q PKGPATH -a", self.cmd] split:@"\n"]];
    [output removeLastObject];
    [ids removeLastObject];
    NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    int i = 0;
    for (NSString *line in output) {
        NSUInteger sep = [line rangeOfString:@" "].location;
        NSString *name = [line substringToIndex:sep];
        NSString *description = [[line substringFromIndex:sep+1] stringByTrimmingCharactersInSet:whitespaceCharacterSet];
        sep = [name rangeOfString:@"-" options:NSBackwardsSearch].location;
        NSString *version = [name substringFromIndex:sep+1];
        // name = [name substringToIndex:sep];
        NSString *ID= ids[i];
        sep = [ID rangeOfString:@"/"].location;
        name = [ID substringFromIndex:sep+1];
        status = GUpToDateStatus;
        GPackage *pkg = self[ID];
        NSString *latestVersion = (pkg == nil) ? nil : [pkg.version copy];
        if (pkg == nil) {
            pkg = [[GPackage alloc] initWithName:name
                                             version:latestVersion
                                              system:self
                                              status:status];
            self[ID] = pkg;
        } else {
            if (pkg.status == GAvailableStatus)
                pkg.status = GUpToDateStatus;
        }
        pkg.installed = version;
        pkg.description = description;
        pkg.ID = ID;
        [pkgs addObject:pkg];
        i++;
    }
    return pkgs;
}


// TODO: pkg_info -d

// TODO: pkg_info -B PKGPATH=misc/figlet


- (NSString *)info:(GItem *)item {
    if (self.isHidden)
        return [super info:item];
    if (self.mode != GOfflineMode && item.status != GAvailableStatus)
        return [self outputFor:@"%@ %@", self.cmd, item.name];
    else {
        if (item.ID != nil)
            return [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/%@/DESCR", item.ID]] encoding:NSUTF8StringEncoding error:nil];
        else // TODO lowercase (i.e. Hermes -> hermes)
            return [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/%@/%@/DESCR", item.categories, item.name]] encoding:NSUTF8StringEncoding error:nil];
    }
}

- (NSString *)home:(GItem *)item {
    if (item.homepage != nil) // already available from INDEX
        return item.homepage;
    else {
        NSArray *links = [self.agent nodesForURL:[NSString stringWithFormat:@"http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/%@/%@/README.html", item.categories, item.name] XPath:@"//p/a"];
        return [links[2] href];
    }
}

- (NSString *)log:(GItem *)item {
    if (item != nil ) {
        if (item.ID != nil)
            return [NSString stringWithFormat:@"http://cvsweb.NetBSD.org/bsdweb.cgi/pkgsrc/%@/", item.ID];
        else
            return [NSString stringWithFormat:@"http://cvsweb.NetBSD.org/bsdweb.cgi/pkgsrc/%@/%@/", item.categories, item.name];
    } else {
        return @"http://www.netbsd.org/changes/pkg-changes.html";
    }
}


- (NSString *)contents:(GItem *)item {
    if (item.status != GAvailableStatus)
        return [[self outputFor:@"%@ -L %@", self.cmd, item.name] split:@"Files:\n"][1];
    else {
        if (item.ID != nil)
            return [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/%@/PLIST", item.ID]] encoding:NSUTF8StringEncoding error:nil];
        else
            return [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/%@/%@/PLIST", item.categories, item.name]] encoding:NSUTF8StringEncoding error:nil];
    }
}

- (NSString *)cat:(GItem *)item {
    if (item.status != GAvailableStatus) {
        NSArray *filtered = [self.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", item.name]];
        item.ID = ((GPackage *)filtered[0]).ID;
    }
    if (item.ID != nil)
        return [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/%@/Makefile", item.ID]] encoding:NSUTF8StringEncoding error:nil];
    else
        return [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/%@/%@/Makefile", item.categories, item.name]] encoding:NSUTF8StringEncoding error:nil];
}

// TODO: Deps: pkg_info -n -r, scrape site, parse Index

- (NSString *)deps:(GItem *)item { // FIXME: "*** PACKAGE MAY NOT BE DELETED *** "
    if (item.status != GAvailableStatus) {
        NSArray *components = [[self outputFor:@"%@ -n %@", self.cmd, item.name] split:@"Requires:\n"];
        if ([components count] > 1) {
            return [components[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        } else
            return @"[No depends]";
    } else {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[@"~/Library/Application Support/Guigna/pkgsrc/INDEX" stringByExpandingTildeInPath]]) {
            // TODO: parse INDEX
            // NSArray *lines = [NSString stringWithContentsOfFile:[@"~/Library/Application Support/Guigna/pkgsrc/INDEX" stringByExpandingTildeInPath] encoding:NSUTF8StringEncoding error:nil];
        }
        return @"[Not available]";
    }
}

- (NSString *)dependents:(GItem *)item {
    if (item.status != GAvailableStatus) {
        NSArray *components = [[self outputFor:@"%@ -r %@", self.cmd, item.name] split:@"required by list:\n"];
        if ([components count] > 1) {
            return [components[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        } else
            return @"[No dependents]";
    } else
        return @"[Not available]";
}

- (NSString *) installCmd:(GPackage *)pkg {
    if (pkg.ID != nil)
        return [NSString stringWithFormat:@"cd /usr/pkgsrc/%@ ; sudo /usr/pkg/bin/bmake install clean clean-depends", pkg.ID];
    else
        return [NSString stringWithFormat:@"cd /usr/pkgsrc/%@/%@ ; sudo /usr/pkg/bin/bmake install clean clean-depends", pkg.categories, pkg.name];
}

- (NSString *) uninstallCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"sudo %@/sbin/pkg_delete %@", self.prefix, pkg.name];
}

- (NSString *) cleanCmd:(GPackage *)pkg {
    if (pkg.ID != nil)
        return [NSString stringWithFormat:@"cd /usr/pkgsrc/%@ ; sudo /usr/pkg/bin/bmake clean clean-depends", pkg.ID];
    else
        return [NSString stringWithFormat:@"cd /usr/pkgsrc/%@/%@ ; sudo /usr/pkg/bin/bmake clean clean-depends", pkg.categories, pkg.name];
}

- (NSString *)updateCmd {
    if (self.mode == GOnlineMode || [self.agent.appDelegate.defaults[@"pkgsrcCVS"] isEqual:@NO])
        return nil;
    else
        return @"sudo cd; cd /usr/pkgsrc ; sudo cvs update -dP";
}

- (NSString *)hideCmd {
    return [NSString stringWithFormat:@"sudo mv %@ %@_off", self.prefix, self.prefix];
}

- (NSString *)unhideCmd {
    return [NSString stringWithFormat:@"sudo mv %@_off %@", self.prefix, self.prefix];
}


+ (NSString *)setupCmd {
    return @"sudo mv /usr/local /usr/local_off ; sudo mv /opt/local /opt/local_off ; sudo mv /sw /sw_off ; cd ~/Library/Application\\ Support/Guigna/pkgsrc ; curl -L -O ftp://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc.tar.gz ; sudo tar -xvzf pkgsrc.tar.gz -C /usr; cd /usr/pkgsrc/bootstrap ; sudo ./bootstrap --compiler clang; sudo mv /usr/local_off /usr/local ; sudo mv /opt/local_off /opt/local ; sudo mv /sw_off /sw";
}

+ (NSString *)removeCmd {
    return @"sudo rm -r /usr/pkg ; sudo rm -r /usr/pkgsrc ; sudo rm -r /var/db/pkg";
}


@end
