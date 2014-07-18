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

- (NSArray *)items {
    NSMutableArray *items = [NSMutableArray array];
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
        NSUInteger sep = [ID rangeOfString:@"/" options:NSBackwardsSearch].location;
        NSString *name = [ID substringFromIndex:sep+1];
        NSString *category = [ID substringToIndex:sep];
        NSString *version = [dates[i] stringValue];
        sep = [version rangeOfString:@" ("].location;
        if (sep != NSNotFound) {
            version = [version substringFromIndex:sep+2];
            version = [version substringToIndex:([version rangeOfString:@")"].location)];
        } else {
            version = [[version split] lastObject];
        }
        NSString *description = [comments[i] stringValue];
        description = [description substringToIndex:([description rangeOfString:@"\n"].location)];
        description = [description substringFromIndex:([description rangeOfString:@": "].location)+2];
        GItem *item = [[GItem alloc] initWithName:name
                                          version:version
                                           source:self
                                           status:GAvailableStatus];
        item.ID = ID;
        item.description = description;
        item.categories = category;
        [items addObject:item];
        i++;
    }
    return items;
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
