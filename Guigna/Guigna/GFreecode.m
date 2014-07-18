#import "GFreecode.h"
#import "GAdditions.h"

@implementation GFreecode

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Freecode" agent:agent];
    if (self) {
        self.homepage = @"http://freecode.com/";
        self.itemsPerPage = 25;
        self.cmd = @"freecode";
    }
    return self;
}

// TODO: 

- (NSArray *)items {
    NSMutableArray *items = [NSMutableArray array];
    NSString *url = [NSString stringWithFormat:@"http://freecode.com/?page=%ld", self.pageNumber];
    NSArray *nodes = [self.agent nodesForURL:url XPath:@"//div[contains(@class,\"release\")]"];
    for (id node in nodes) {
        NSString *name = [[node[@"h2/a"] lastObject] stringValue];
        NSUInteger sep = [name rangeOfString:@" " options:NSBackwardsSearch].location;
        NSString *version = [name substringFromIndex:sep+1];
        name = [name substringToIndex:sep];
        NSString *ID = [[[node[@"h2/a"] lastObject] href] lastPathComponent];
        NSArray *moreinfo = node[@"h2//a[contains(@class,\"moreinfo\")]"];
        NSString *homepage;
        if ([moreinfo count] == 0)
            homepage = self.homepage;
        else {
            homepage = moreinfo[0][@"@title"];
            NSUInteger sep = [homepage rangeOfString:@" " options:NSBackwardsSearch].location;
            homepage = [homepage substringFromIndex:sep+1];
            if (![homepage hasPrefix:@"http://"])
                homepage = [@"http://" stringByAppendingString:homepage]; 
        }
        NSArray *taglist = node[@"ul/li"];
        NSMutableArray *tags = [NSMutableArray array];
        for (id node in taglist) {
            [tags addObject:[node stringValue]];
        }
        // NSString *category = 
        GItem *item = [[GItem alloc] initWithName:name
                                          version:version
                                           source:self
                                           status:GAvailableStatus];
        item.ID = ID;
        item.description = [tags join];
        item.homepage = homepage;
        [items addObject:item];
    }
    return items;
}

// TODO: parse log page
- (NSString *)home:(GItem *)item {
    return item.homepage;
}

- (NSString *)log:(GItem *)item {
    return [NSString stringWithFormat:@"http://freecode.com/projects/%@", item.ID];
}

@end
