#import "GPkgsrcSE.h"
#import "GAdditions.h"


@implementation GPkgsrcSE

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Pkgsrc.se" agent:agent];
    if (self) {
        self.homepage = @"http://pkgsrc.se/";
        self.itemsPerPage = 15;
        self.cmd = @"pkgsrc";
    }
    return self;
}

- (void)refresh {
    NSMutableArray *entries = [NSMutableArray array];
    NSString *url = [NSString stringWithFormat:@"http://pkgsrc.se/?page=%ld", self.pageNumber];
    id mainDiv = [self.agent nodesForURL:url XPath:@"//div[@id=\"main\"]"][0];
    NSArray *dates = mainDiv[@"h3"];
    NSMutableArray *names = [NSMutableArray arrayWithArray:mainDiv[@"b"]];
    [names removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)]];
    NSMutableArray *comments = [NSMutableArray arrayWithArray:mainDiv[@"div"]];
    [comments removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)]];
    
    int i = 0;
    for (id node in names) {
        NSString *ID = [node[@"a"][0] stringValue];
        NSUInteger idx = [ID rindex:@"/"];
        NSString *name = [ID substringFromIndex:idx + 1];
        NSString *category = [ID substringToIndex:idx];
        NSString *version = [dates[i] stringValue];
        idx = [version index:@" ("];
        if (idx != NSNotFound) {
            version = [version substringFromIndex:idx + 2];
            version = [version substringToIndex:([version index:@")"])];
        } else {
            version = [[version split] lastObject];
        }
        NSString *description = [comments[i] stringValue];
        description = [description substringToIndex:([description index:@"\n"])];
        description = [description substringFromIndex:([description index:@": "]) + 2];
        GItem *entry = [[GItem alloc] initWithName:name
                                          version:version
                                           source:self
                                           status:GAvailableStatus];
        entry.ID = ID;
        entry.description = description;
        entry.categories = category;
        [entries addObject:entry];
        i++;
    }
    self.items = entries;
}

- (NSString *)home:(GItem *)item {
    NSArray *links = [self.agent nodesForURL:[NSString stringWithFormat:@"http://pkgsrc.se/%@", item.ID] XPath:@"//div[@id=\"main\"]//a"];
    NSString *home = [links[2] href];
    return home;
}

- (NSString *)log:(GItem *)item {
    return [NSString stringWithFormat:@"http://pkgsrc.se/%@", item.ID];
}

@end
