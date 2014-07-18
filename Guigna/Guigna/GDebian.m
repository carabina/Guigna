#import "GDebian.h"

#import "GAdditions.h"

@implementation GDebian

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Debian" agent:agent];
    if (self) {
        self.homepage = @"http://packages.debian.org/unstable/";
        self.itemsPerPage = 100;
        self.cmd = @"apt-get";
    }
    return self;
}


- (NSArray *)items {
    NSMutableArray *items = [NSMutableArray array];
    NSString *url = [NSString stringWithFormat:@"http://news.gmane.org/group/gmane.linux.debian.devel.changes.unstable/last="];
    NSArray *nodes = [self.agent nodesForURL:url XPath:@"//table[@class=\"threads\"]//table/tr"];
    for (id node in nodes) {
        NSString *link = [node[@".//a"][0] stringValue];
        NSArray *components = [link split];
        NSString *name = components[1];
        NSString *version = components[2];
        GItem *item = [[GItem alloc] initWithName:name
                                          version:version
                                           source:self
                                           status:GAvailableStatus];
        [items addObject:item];
    }
    return items;
}

- (NSString *)home:(GItem *)item {
    NSString *page = [self log:item];
    NSArray *links = [self.agent nodesForURL:page XPath:@"//a[text()=\"Homepage\"]"];
    if ([links count] > 0) {
        page = [links[0] href];
    }
    return page;
}

- (NSString *)log:(GItem *)item {
    return [NSString stringWithFormat:@"http://packages.debian.org/sid/%@", item.name];
}

@end
