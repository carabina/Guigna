#import "GRudix.h"
#import "GAdditions.h"

@implementation GRudix

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Rudix" agent:agent];
    if (self) {
        self.homepage = @"http://www.rudix.org/";
        self.itemsPerPage = 100;
        self.cmd = @"rudix";
    }
    return self;
}

- (NSArray *)items {
    NSMutableArray *items = [NSMutableArray array];
    NSString *url = @"http://rudix.org/download/2014/10.9/";
    NSArray *links = [self.agent nodesForURL:url XPath:@"//tbody//tr//a"];
    NSCharacterSet *decimalCharSet = [NSCharacterSet decimalDigitCharacterSet];
    for (id link in links) {
        NSString *name = [link stringValue];
        if ([name hasPrefix:@"Parent Dir"] || [name contains:@"MANIFEST"])
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
        GItem *item = [[GItem alloc] initWithName:name
                                          version:version
                                           source:self
                                           status:GAvailableStatus];
        item.homepage = [NSString stringWithFormat:@"http://rudix.org/packages/%@.html", item.name];
        [items addObject:item];
    }
    return items;
}

- (NSString *)log:(GItem *)item {
    return [NSString stringWithFormat:@"https://github.com/rudix-mac/rudix/commits/master/Ports/%@", item.name];
}


// TODO:
+ (NSString *)setupCmd {
    return @"curl -s https://raw.github.com/rudix-mac/package-manager/master/rudix.py | sudo python - install rudix";
}

@end