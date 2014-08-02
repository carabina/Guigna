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

- (NSString *)clampedOSVersion {
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
    NSString *osxVersion = [self clampedOSVersion];
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
        [self.items addObject:pkg];
        self[name] = pkg;
    }
    [self installed]; // update status
    return self.items;
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
        NSUInteger sep = [name rangeOfString:@"-"].location;
        NSString *version = [name substringFromIndex:sep+1];
        version = [version substringToIndex:[version length]-4];
        if (![decimalCharSet characterIsMember:[version characterAtIndex:0]]) {
            NSUInteger sep2 = [version rangeOfString:@"-"].location;
            version = [version substringFromIndex:sep2+1];
            sep += sep2+1;
        }
        name = [name substringToIndex:sep];
        GItem *pkg = [[GItem alloc] initWithName:name
                                         version:version
                                          source:self
                                          status:GAvailableStatus];
        pkg.homepage = [NSString stringWithFormat:@"http://rudix.org/packages/%@.html", pkg.name];
        [pkgs addObject:pkg];
    }
    self.items = pkgs;
}

- (NSString *)log:(GItem *)item {
    if (item != nil ) {
        return [NSString stringWithFormat:@"https://github.com/rudix-mac/rudix/commits/master/Ports/%@", item.name];
    } else {
        return @"https://github.com/rudix-mac/rudix/commits";
    }
}


// TODO:
+ (NSString *)setupCmd {
    return @"curl -s https://raw.githubusercontent.com/rudix-mac/rpm/master/rudix.py | sudo python - install rudix";
}

@end