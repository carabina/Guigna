#import "GPyPI.h"
#import "GAdditions.h"


@implementation GPyPI

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"PyPI" agent:agent];
    if (self) {
        self.homepage = @"http://pypi.python.org/pypi";
        self.itemsPerPage = 40;
        self.cmd = @"pip";
    }
    return self;
}

- (NSArray *)items {
    NSMutableArray *eggs = [NSMutableArray array];
    NSMutableArray *nodes = [[self.agent nodesForURL:self.homepage XPath:@"//table[@class=\"list\"]//tr"] mutableCopy];
    [nodes removeObjectAtIndex:0];
    [nodes removeLastObject];
    NSString *name;
    NSString *version;
    NSString *date;
    NSString *link;
    NSString *description;
    for (id node in nodes) {
        NSArray *rowData = node[@"td"];
        date = [rowData[0] stringValue];
        link = [rowData[1][@"a"][0] href];
        NSArray *splits = [link split:@"/"];
        name = splits[[splits count]-2];
        version = splits[[splits count]-1];
        description = [rowData[2] stringValue];
        GItem *egg = [[GItem alloc] initWithName:name
                                         version:version
                                          source:self
                                          status:GAvailableStatus];
        egg.description = description;
        [eggs addObject:egg];
    }
    return eggs;
}

- (NSString *)home:(GItem *)item {
    return [[self.agent nodesForURL:[self log:item] XPath:@"//ul[@class=\"nodot\"]/li/a"][0] stringValue];
    // if nil return [self log:item];
}

- (NSString *)log:(GItem *)item {
    return [NSString stringWithFormat:@"%@/%@/%@", self.homepage, item.name, item.version];
}



@end
