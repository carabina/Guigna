#import "GRubyGems.h"
#import "GAdditions.h"


@implementation GRubyGems

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"RubyGems" agent:agent];
    if (self) {
        self.homepage = @"http://rubygems.org/";
        self.itemsPerPage = 25;
        self.cmd = @"gem";
    }
    return self;
}

- (void)refresh {
    NSMutableArray *gems = [NSMutableArray array];
    NSString *url = @"http://m.rubygems.org/";
    NSArray *nodes = [self.agent nodesForURL:url XPath:@"//li"];
    NSString *name;
    NSString *version;
    NSString *date;
    NSString *info;
    for (id node in nodes) {
        NSArray *components = [[node stringValue] split];
        name = components[0];
        version = components[1];
        NSArray *spans = node[@".//span"];
        date = [spans[0] stringValue];
        info = [spans[1] stringValue];
        GItem *gem = [[GItem alloc] initWithName:name
                                         version:version
                                          source:self
                                          status:GAvailableStatus];
        gem.description = info;
        [gems addObject:gem];
    }
    self.items = gems;
}

- (NSString *)home:(GItem *)item {
    NSString *page = [self log:item];
    NSArray *links = [self.agent nodesForURL:page XPath:@"//div[@class=\"links\"]/a"];
    if ([links count] > 0) {
        for (id link in links) {
            if ([[link stringValue] is:@"Homepage"]) {
                page = [link href];
            }
        }
    }
    return page;
}

- (NSString *)log:(GItem *)item {
    return [NSString stringWithFormat:@"%@gems/%@", self.homepage, item.name];
}

@end
