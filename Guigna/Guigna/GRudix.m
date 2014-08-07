#import "GRudix.h"
#import "GPackage.h"
#import "GLibrary.h"

@implementation GRudix

+ (NSString *)prefix {
    return @"/usr/local";
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Rudix" agent:agent];
    if (self) {
        self.homepage = @"http://rudix.org/";
        self.cmd = [NSString stringWithFormat:@"%@/bin/rudix", self.prefix];
    }
    return self;
}

+ (NSString *)clampedOSVersion {
    NSString *osVersion = [G OSVersion];
    if ([osVersion compare:@"10.6" options:NSNumericSearch] == NSOrderedAscending || [osVersion compare:@"10.9"options:NSNumericSearch] == NSOrderedDescending ) {
        osVersion = @"10.9";
    }
    return osVersion;
}


- (NSArray *)list {
    [self.index removeAllObjects];
    [self.items removeAllObjects];
    NSString *command = [NSString stringWithFormat: @"%@ search", self.cmd];
    NSString *osxVersion = [GRudix clampedOSVersion];
    if (![[G OSVersion] is:osxVersion]) {
        command = [NSString stringWithFormat:@"/bin/sh -c export__OSX_VERSION=%@__;__%@__search", osxVersion,  self.cmd];
    }
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:command] split:@"\n"]];
    [output removeLastObject];
    for (NSString *line in output) {
        NSMutableArray *components = [NSMutableArray arrayWithArray:[line split:@"-"]];
        NSMutableString *name = [NSMutableString stringWithString:components[0]];
        if ([components count] == 4) {
            [name appendFormat:@"-%@", components[1]];
            [components removeObjectAtIndex:1];
        }
        NSMutableString *version = [NSMutableString stringWithString:components[1]];
        [version appendFormat:@"-%@", [((NSString *)components[2]) split:@"."][0]];
        GPackage *pkg = [[GPackage alloc] initWithName:name
                                               version:version
                                                system:self
                                                status:GAvailableStatus];
        if (self[name] != nil) {
            GPackage *prevPackage = self[name];
            [self.items removeObjectIdenticalTo:prevPackage];
        }
        [self.items addObject:pkg];
        self[name] = pkg;
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
    NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@", self.cmd] split:@"\n"]];
    [output removeLastObject];
    GStatus status;
    for (GPackage *pkg in self.items) {
        status = pkg.status;
        pkg.installed = nil;
        if (status != GUpdatedStatus && status != GNewStatus)
            pkg.status = GAvailableStatus;
    }
    // [self outdated]; // update status
    NSString *name;
    for (NSString *line in output) {
        name = [line substringFromIndex:[line rindex:@"."] + 1];
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
        pkg.installed = @""; // TODO
        [pkgs addObject:pkg];
    }
    return pkgs;
}



- (void)refresh { // TODO: convert from GRepo to GOnlineMode GSystem
    NSMutableArray *pkgs = [NSMutableArray array];
    NSString *url = @"http://rudix.org/download/2014/10.9/";
    NSArray *links = [self.agent nodesForURL:url XPath:@"//tbody//tr//a"];
    NSCharacterSet *decimalCharSet = [NSCharacterSet decimalDigitCharacterSet];
    for (id link in links) {
        NSString *name = [link stringValue];
        if ([name hasPrefix:@"Parent Dir"] || [name contains:@"MANIFEST"] || [name contains:@"ALIASES"])
            continue;
        NSUInteger idx = [name index:@"-"];
        NSString *version = [name substringFromIndex:idx + 1];
        version = [version substringToIndex:[version length]-4];
        if (![decimalCharSet characterIsMember:[version characterAtIndex:0]]) {
            NSUInteger idx2 = [version index:@"-"];
            version = [version substringFromIndex:idx2 + 1];
            idx += idx2 + 1;
        }
        name = [name substringToIndex:idx];
        GItem *pkg = [[GItem alloc] initWithName:name
                                         version:version
                                          source:self
                                          status:GAvailableStatus];
        pkg.homepage = [NSString stringWithFormat:@"http://rudix.org/packages/%@.html", pkg.name];
        [pkgs addObject:pkg];
    }
    self.items = pkgs;
}

- (NSString *)home:(GItem *)item {
    return [NSString stringWithFormat:@"http://rudix.org/packages/%@.html", item.name];
}

- (NSString *)log:(GItem *)item {
    if (item != nil ) {
        return [NSString stringWithFormat:@"https://github.com/rudix-mac/rudix/commits/master/Ports/%@", item.name];
    } else {
        return @"https://github.com/rudix-mac/rudix/commits";
    }
}

- (NSString *)contents:(GItem *)item {
    if (item.installed != nil)
        return [self outputFor:@"%@ --files %@", self.cmd, item.name];
    else // TODO: parse http://rudix.org/packages/%@.html
        return @"";
}

- (NSString *)cat:(GItem *)item {
    return [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://raw.githubusercontent.com/rudix-mac/rudix/master/Ports/%@/Makefile", item.name]] encoding:NSUTF8StringEncoding error:nil];
}


- (NSArray *)availableCommands {
    return [super availableCommands];
}


- (NSString *)installCmd:(GPackage *)pkg {
    NSString *command = [NSString stringWithFormat: @"%@ install %@", self.cmd, pkg.name];
    NSString *osxVersion = [GRudix clampedOSVersion];
    if (![[G OSVersion] is:osxVersion]) {
        command = [NSString stringWithFormat:@"OSX_VERSION=%@ %@", osxVersion,  command];
    }
    return [NSString stringWithFormat:@"sudo %@", command];
}

- (NSString *)uninstallCmd:(GPackage *)pkg {
    return [NSString stringWithFormat:@"sudo %@ remove %@", self.cmd, pkg.name];
}


- (NSString *)hideCmd {
    return [NSString stringWithFormat:@"sudo mv %@ %@_off", self.prefix, self.prefix];
}

- (NSString *)unhideCmd {
    return [NSString stringWithFormat:@"sudo mv %@_off %@", self.prefix, self.prefix];
}

+ (NSString *)setupCmd {
    NSString *command = [NSString stringWithFormat:@"curl -s https://raw.githubusercontent.com/rudix-mac/rpm/master/rudix.py | sudo python - install rudix"];
    NSString *osxVersion = [GRudix clampedOSVersion];
    if (![[G OSVersion] is:osxVersion]) {
        command = [NSString stringWithFormat:@"curl -s https://raw.githubusercontent.com/rudix-mac/rpm/master/rudix.py | sudo OSX_VERSION=%@ python - install rudix", osxVersion];
    }
    return command;
}

@end