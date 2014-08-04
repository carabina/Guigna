#import "GMacUpdate.h"
#import "GAdditions.h"

@implementation GMacUpdate

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"MacUpdate" agent:agent];
    if (self) {
        self.homepage = @"http://www.macupdate.com";
        self.itemsPerPage = 80;
        self.cmd = @"macupdate";
    }
    return self;
}


- (void)refresh {
    NSMutableArray *entries = [NSMutableArray array];
    NSString *url = [NSString stringWithFormat:@"https://www.macupdate.com/apps/page/%ld", self.pageNumber - 1];
    NSArray *nodes = [self.agent nodesForURL:url XPath:@"//div[@class=\"appinfo\"]"];
    for (id node in nodes) {
        NSString *name = [node[@"a"][0] stringValue];
        NSUInteger idx = [name rindex:@" "];
        NSString *version = @"";
        if (idx != NSNotFound) {
            version = [name substringFromIndex:idx + 1];
            name = [name substringToIndex:idx];
        }
        NSString *description = [[node[@"span"][0] stringValue] substringFromIndex:2];
        NSString *ID = [[node[@"a"][0] href] split:@"/"][3];
        // NSString *category =
        GItem *entry = [[GItem alloc] initWithName:name
                                           version:version
                                            source:self
                                            status:GAvailableStatus];
        entry.ID = ID;
        // item.categories = category;
        entry.description = description;
        [entries addObject:entry];
    }
    self.items = entries;
}

- (NSString *)home:(GItem *)item {
    NSArray *nodes = [self.agent nodesForURL:[self log:item] XPath:@"//a[@target=\"devsite\"]"];
    // Old:
    // NSString *home = [[[[[nodes objectAtIndex:0] href] split:@"/"] objectAtIndex:3] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    // TODO: redirect
    NSString *home = [NSString stringWithFormat:@"http://www.macupdate.com%@", [[nodes[0] href] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return home;
}

- (NSString *)log:(GItem *)item {
    return [NSString stringWithFormat:@"http://www.macupdate.com/app/mac/%@", item.ID];
}

@end
