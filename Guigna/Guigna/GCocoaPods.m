#import "GCocoaPods.h"
#import "GPackage.h"
#import "GAdditions.h"


@implementation GCocoaPods

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"CocoaPods" agent:agent];
    if (self) {
        self.homepage = @"http://www.cocoapods.org";
        // self.prefix = @"/opt/local";
        // self.cmd = [NSString stringWithFormat:@"%@/bin/pod", self.prefix];
        self.itemsPerPage = 25;
        self.cmd = @"pod";
    }
    return self;
}

- (NSArray *)items {
    NSMutableArray *pods = [NSMutableArray array];
    NSString *url = @"http://feeds.cocoapods.org/new-pods.rss";
    NSArray *nodes = [self.agent nodesForURL:url XPath:@"//item"];
    NSString *name;
    NSString *version = @"";
    NSString *link;
    NSString *date;
    NSString *description;
    for (id node in nodes) {
        name = [node[@"title"][0] stringValue];
        description = [node[@"description"][0] stringValue];
        NSUInteger sep = [description rangeOfString:@"</p>"].location;
        description = [description substringToIndex:sep];
        while ([description hasPrefix:@"<p>"]) {
            description = [description substringFromIndex:3];
        }
        link = [node[@"link"][0] stringValue];
        date = [node[@"pubDate"][0] stringValue];
        date = [date substringWithRange:NSMakeRange(4,12)];
        GItem *pod = [[GItem alloc] initWithName:name
                                         version:version
                                          source:self
                                          status:GAvailableStatus];
        pod.description = description;
        pod.homepage = link;
        [pods addObject:pod];
    }
    return pods;
}

- (NSString *)home:(GItem *)item {
    return item.homepage;
}


- (NSString *)log:(GItem *)item {
    if (item != nil ) {
        return [NSString stringWithFormat:@"http://github.com/CocoaPods/Specs/tree/master/%@", item.name];
    } else {
        return @"http://github.com/CocoaPods/Specs/commits";
    }
}

/*
 - (NSArray *)list {
 NSMutableArray *output = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ list --no-color", self.cmd] split:@"--> "]];
 [output removeObjectAtIndex:0];
 [self.index removeAllObjects];
 [self.items removeAllObjects];
 for (NSString *pod in output) {
 NSArray *lines = [pod split:@"\n"];
 NSUInteger sep = [lines[0] rangeOfString:@" (" options:NSBackwardsSearch].location;
 NSString *name = [lines[0] substringToIndex:sep];
 NSString *version = [lines[0] substringWithRange:NSMakeRange(sep+2, [lines[0] length]-sep-3)];
 GPackage *package = [[GPackage alloc] initWithName:name
 version:version
 system:self
 status:GAvailableStatus];
 NSMutableString *description = [NSMutableString string];
 NSString *nextLine;
 int i = 1;
 while (![(nextLine = [lines[i++] substringFromIndex:4]) hasPrefix:@"- "]) {
 if (i !=2)
 [description appendString:@" "];
 [description appendString:nextLine];
 };
 package.description = description;
 if ([nextLine hasPrefix:@"- Homepage:"]) {
 package.homepage = [nextLine substringFromIndex:12];
 }
 [self.items addObject:package];
 (self.index)[[package key]] = package;
 }
 // TODO
 //    for (GPackage *package in self.installed) {
 //        ((GPackage *)[self.index objectForKey:[package key]]).status = package.status;
 //    }
 return self.items;
 }
 

 
 // TODO
 - (NSString *)info:(GItem *)item {
 return [self outputFor:@"%@ search --stats --no-color %@", self.cmd, item.name];
 }
 
 - (NSString *)home:(GItem *)item {
 return item.homepage;
 }
 
 - (NSString *)log:(GItem *)item {
 if (item != nil ) {
 return [NSString stringWithFormat:@"http://github.com/CocoaPods/Specs/tree/master/%@", item.name];
 } else {
 return @"http://github.com/CocoaPods/Specs/commits";
 }

 
 - (NSString *)contents:(GItem *)item {
 return [self outputFor:@"%@ search --stats --no-color %@", self.cmd, item.name];
 }
 
 // TODO:
 - (NSString *)cat:(GItem *)item {
 return [self outputFor:@"%@ cat %@", self.cmd, item.name];
 }
 
 - (NSString *)deps:(GItem *)item {
 return [self outputFor:@"%@ search --stats --no-color %@", self.cmd, item.name];
 }
 
 - (NSString *)dependents:(GItem *)item {
 return [self outputFor:@"%@ search --stats --no-color %@", self.cmd, item.name];
 }
 
 
 - (NSString *)updateCmd {
 return [NSString stringWithFormat:@"%@ repo update  --no-color", self.cmd];
 }
 
 // TODO:
 + (NSString *)setupCmd {
 return @"sudo /opt/local/bin/gem1.9 install pod; /opt/local/bin/pod setup";
 }
 
 + (NSString *)removeCmd {
 return @"sudo /opt/local/bin/gem1.9 uninstall pod";
 }
 */
@end
