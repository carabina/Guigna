#import "GAppShopper.h"
#import "GAdditions.h"

@implementation GAppShopper

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"AppShopper" agent:agent];
    if (self) {
        self.homepage = @"http://appshopper.com/mac/all/";
        self.itemsPerPage = 20;
        self.cmd = @"appstore";
    }
    return self;
}

- (NSArray *)items {
    NSMutableArray *items = [NSMutableArray array];
    NSString *url = [NSString stringWithFormat:@"http://appshopper.com/mac/all/%ld", self.pageNumber];
    NSArray *nodes =[self.agent nodesForURL:url XPath:@"//ul[@class=\"appdetails\"]/li"];
    for (id node in nodes) {
        NSString *name = [node[@"h3/a"][0] stringValue];
        NSString *version = [node[@".//dd"][2] stringValue];
        version = [version substringToIndex:[version length]-1]; // trim final \n
        NSString *ID = [node[@"@id"] substringFromIndex:4];
        NSString *nick = [[node[@"a"][0] href] lastPathComponent];
        ID = [ID stringByAppendingFormat:@" %@", nick];
        NSString *category = [node[@"div[@class=\"category\"]"][0] stringValue];
        category = [category substringToIndex:[category length]-1]; // trim final \n
        NSString *type = node[@"@class"];
        NSString *price = [[node[@".//div[@class=\"price\"]"][0] children][0] stringValue];
        NSString *cents = [[node[@".//div[@class=\"price\"]"][0] children][1] stringValue];
        if ([price is:@""])
            price = cents;
        else if ( ![cents hasPrefix:@"Buy"])
            price = [NSString stringWithFormat:@"%@.%@", price, cents];
        // TODO:NSXML UTF8 encoding
        NSMutableString *fixedPrice = [price mutableCopy];
        [fixedPrice replaceOccurrencesOfString:@"â‚¬" withString:@"€" options:0 range:NSMakeRange(0, [fixedPrice length])];
        GItem *item = [[GItem alloc] initWithName:name
                                          version:version
                                           source:self
                                           status:GAvailableStatus];
        item.ID = ID;
        item.categories = category;
        item.description = [NSString stringWithFormat:@"%@ %@", type, fixedPrice];
        [items addObject:item];
    }
    return items;

}

- (NSString *)home:(GItem *)item {
    id mainDiv =[self.agent nodesForURL:[@"http://itunes.apple.com/app/id" stringByAppendingString:[item.ID split][0]] XPath:@"//div[@id=\"main\"]"][0];
    NSArray *links = mainDiv[@"//div[@class=\"app-links\"]/a"];
    NSArray *screenshotsImgs = mainDiv[@"//div[contains(@class, \"screenshots\")]//img"];
    NSMutableString *screenshots = [NSMutableString string];
    NSInteger i = 0;
    for (id img in screenshotsImgs) {
        NSString *url = img[@"@src"];
        if (i > 0)
            [screenshots appendString:@" "];
        [screenshots appendString:url];
        i++;
    }
    item.screenshots = screenshots;
    NSString *homepage = [links[0] href];
    if ([homepage is:@"http://"])
        homepage = [links[1] href];
    return homepage;
}

- (NSString *)log:(GItem *)item {
    NSString *name = [item.ID split][1];
    NSString *category = [[item.categories stringByReplacingOccurrencesOfString:@" " withString:@"-"] lowercaseString];
    category = [[category stringByReplacingOccurrencesOfString:@"-&-" withString:@"-"] lowercaseString]; // fix Healthcare & Fitness
    return [NSString stringWithFormat:@"http://www.appshopper.com/mac/%@/%@", category, name];
}

@end
