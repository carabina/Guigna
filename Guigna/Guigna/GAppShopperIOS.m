#import "GAppShopperIOS.h"
#import "GAdditions.h"

@implementation GAppShopperIOS

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"AppShopper iOS" agent:agent];
    if (self) {
        self.homepage = @"http://appshopper.com/all/";
        self.itemsPerPage = 20;
        self.cmd = @"appstore";
    }
    return self;
}

- (void)refresh {
    NSMutableArray *apps = [NSMutableArray array];
    NSString *url = [NSString stringWithFormat:@"http://appshopper.com/all/%ld", self.pageNumber];
    NSArray *nodes =[self.agent nodesForURL:url XPath:@"//ul[@class=\"appdetails\"]/li"];
    for (id node in nodes) {
        NSString *name = [node[@"h3/a"][0] stringValue];
        NSString *version = [node[@".//dd"][2] stringValue];
        version = [version substringToIndex:[version length]-1]; // trim final \n
        NSString *ID = [node[@"@id"] substringFromIndex:4];
        NSString *nick = [[node[@"a"][0] href] lastPathComponent];
        ID = [ID stringByAppendingFormat:@" %@", nick];
        NSString *category = [node[@"div[@class=\"category\"]"][0]stringValue];
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
        GItem *app = [[GItem alloc] initWithName:name
                                          version:version
                                           source:self
                                           status:GAvailableStatus];
        app.ID = ID;
        app.categories = category;
        app.description = [NSString stringWithFormat:@"%@ %@", type, fixedPrice];
        [apps addObject:app];
    }
    self.items = apps;
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
    NSString *home = [links[0] href];
    if ([home is:@"http://"])
        home = [links[1] href];
    return home;
}

- (NSString *)log:(GItem *)item {
    NSString *name = [item.ID split][1];
    NSString *category = [[item.categories stringByReplacingOccurrencesOfString:@" " withString:@"-"] lowercaseString];
    category = [[category stringByReplacingOccurrencesOfString:@"-&-" withString:@"-"] lowercaseString]; // fix Healthcare & Fitness
    return [NSString stringWithFormat:@"http://www.appshopper.com/%@/%@", category, name];
}

@end
