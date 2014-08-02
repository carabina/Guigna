#import "GFreeBSD.h"
#import "GPackage.h"
#import "GAdditions.h"


@implementation GFreeBSD

+ (NSString *)prefix {
    return @"";
}


- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"FreeBSD" agent:agent];
    if (self) {
        self.homepage = @"http://www.freebsd.org/ports/";
        self.cmd = [NSString stringWithFormat:@"%@freebsd", self.prefix];
    }
    return self;
}

- (NSArray *)list {
    [self.index removeAllObjects];
    [self.items removeAllObjects];
    NSString *indexPath = [@"~/Library/Application Support/Guigna/FreeBSD/INDEX" stringByExpandingTildeInPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:indexPath]) {
        NSArray *lines = [[NSString stringWithContentsOfFile:indexPath encoding:NSUTF8StringEncoding error:nil]split:@"\n"];
        for (NSString *line in lines) {
            NSArray *components = [line split:@"|"];
            NSString *name = components[0];
            NSUInteger sep = [name rangeOfString:@"-" options:NSBackwardsSearch].location;
            if (sep == NSNotFound)
                continue;
            NSString *version = [name substringFromIndex:sep+1];
            name = [name substringToIndex:sep];
            NSString *description = components[3];
            NSString *category = components[6];
            NSString *homepage = components[9];
            GPackage *pkg = [[GPackage alloc] initWithName:name
                                                   version:version
                                                    system:self
                                                    status:GAvailableStatus];
            pkg.categories = category;
            pkg.description = description;
            pkg.homepage = homepage;
            [self.items addObject:pkg];
            // [self.index setObject:pkg forKey:[pkg key]];
        }
    } else {
        id root = [self.agent nodesForURL:@"http://www.freebsd.org/ports/master-index.html" XPath:@"/*"][0];
        NSArray *names = root[@"//p/strong/a"];
        NSArray *descriptions = root[@"//p/em"];
        int i = 0;
        for (id node in names) {
            NSString *name = [node stringValue];
            NSUInteger sep = [name rangeOfString:@"-" options:NSBackwardsSearch].location;
            NSString *version = [name substringFromIndex:sep+1];
            name = [name substringToIndex:sep];
            NSString *category = [node href];
            category = [category substringToIndex:[category rangeOfString:@".html"].location];
            NSString *description = [descriptions[i] stringValue];
            GPackage *pkg = [[GPackage alloc] initWithName:name
                                                   version:version
                                                    system:self
                                                    status:GAvailableStatus];
            pkg.categories = category;
            pkg.description = description;
            [self.items addObject:pkg];
            // [self.index setObject:pkg forKey:[pkg key]];
            i++;
        }
    }
    //    for (GPackage *pkg in self.installed) {
    //        ((GPackage *)[self.index objectForKey:[pkg key]]).status = pkg.status;
    //    }
    return self.items;
}

- (NSString *)info:(GItem *)item { // TODO: Offline mode
    NSString *category = [item.categories split][0]; // use first category when using INDEX
    NSArray *nodes = [self.agent nodesForURL:[NSString stringWithFormat: @"http://www.FreeBSD.org/cgi/url.cgi?ports/%@/%@/pkg-descr", category, item.name] XPath:@"//pre"];
    if ([nodes count] == 0) {
        nodes = [self.agent nodesForURL:[NSString stringWithFormat: @"http://www.FreeBSD.org/cgi/url.cgi?ports/%@/%@/pkg-descr", category, [item.name lowercaseString]] XPath:@"//pre"];
    }
    if ([nodes count] == 0 )
        return @"[Info not reachable]";
    else
        return [nodes[0] stringValue];
}


- (NSString *)home:(GItem *)item {
    if (item.homepage != nil) // already available from INDEX
        return item.homepage;
    else {
        NSString *category = [item.categories split][0];
        NSArray *nodes = [self.agent nodesForURL:[NSString stringWithFormat:@"http://www.FreeBSD.org/cgi/url.cgi?ports/%@/%@/pkg-descr", category, item.name] XPath:@"//pre/a"];
        if ([nodes count] == 0) {
            nodes = [self.agent nodesForURL:[NSString stringWithFormat: @"http://www.FreeBSD.org/cgi/url.cgi?ports/%@/%@/pkg-descr", category, [item.name lowercaseString]] XPath:@"//pre/a"];
        }
        if ([nodes count] == 0 )
            return self.homepage;
        else
            return [nodes[0] stringValue];
    }
}

// TODO:
- (NSString *)log:(GItem *)item {
    if (item != nil) {
        NSString *category = [item.categories split][0];
        return [NSString stringWithFormat:@"http://www.freshports.org/%@/%@", category, item.name];
    } else
        return @"http://www.freshports.org";
}

- (NSString *)contents:(GItem *)item {
    NSString *category = [item.categories split][0];
    NSString *itemName = item.name;
    NSString *pkgPlist = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat: @"http://svnweb.freebsd.org/ports/head/%@/%@/pkg-plist?view=co", category, itemName]] encoding:NSUTF8StringEncoding error:nil];
    if ([pkgPlist hasPrefix:@"<!DOCTYPE"]) { // 404 File Not Found
        itemName = [itemName lowercaseString];
        pkgPlist = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat: @"http://svnweb.freebsd.org/ports/head/%@/%@/pkg-plist?view=co", category, itemName]] encoding:NSUTF8StringEncoding error:nil];
    }
    if ([pkgPlist hasPrefix:@"<!DOCTYPE"]) { // 404 File Not Found
        pkgPlist = @"";
    }
    return pkgPlist;
}

- (NSString *)cat:(GItem *)item {
    NSString *category = [item.categories split][0];
    NSString *itemName = item.name;
    NSString *makeFile = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat: @"http://svnweb.freebsd.org/ports/head/%@/%@/Makefile?view=co", category, itemName]] encoding:NSUTF8StringEncoding error:nil];
    if ([makeFile hasPrefix:@"<!DOCTYPE"]) { // 404 File Not Found
        itemName = [itemName lowercaseString];
        makeFile = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat: @"http://svnweb.freebsd.org/ports/head/%@/%@/Makefile?view=co", category, itemName]] encoding:NSUTF8StringEncoding error:nil];
    }
    if ([makeFile hasPrefix:@"<!DOCTYPE"]) { // 404 File Not Found
        makeFile = @"[Makefile not reachable]";
    }
    return makeFile;
}


- (NSArray *)availableCommands {
    return [super availableCommands];
}


//# TODO:deps => parse requirements:
// http://www.FreeBSD.org/cgi/ports.cgi?query=%5E' + '%@-%@' item.name-item.version

@end
