#import "GITunes.h"
#import "GPackage.h"
#import "GAdditions.h"

@implementation GITunes

+ (NSString *)prefix {
    return @"";
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"iTunes" agent:agent];
    if (self) {
        self.homepage = @"https://itunes.apple.com/genre/ios/id36?mt=8";
        self.cmd = @"/Applications/iTunes.app/Contents/MacOS/iTunes";
    }
    return self;
}

// TODO:
- (NSArray *)list {
    [self.index removeAllObjects];
    [self.items removeAllObjects];
    [self.items addObjectsFromArray:[self installed]];
    return self.items;
}


- (NSArray *)installed {
    // TODO: status available for uninstalled packages
    NSMutableArray *pkgs = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:[@"~/Music/iTunes/iTunes Media/Mobile Applications" stringByExpandingTildeInPath] error:nil];
    for (NSString *filename in contents) {
        NSString *ipa = [[NSString stringWithFormat:@"~/Music/iTunes/iTunes Media/Mobile Applications/%@", filename] stringByExpandingTildeInPath];
        NSUInteger idx = [filename rindex:@" "];
        if (idx == NSNotFound)
            continue;
        NSString *version = [filename substringWithRange:NSMakeRange(idx + 1, [filename length] - idx - 5)];
        NSString *plist = [self outputFor:@"/usr/bin/unzip -p %@ iTunesMetadata.plist", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"__"]];
        if (plist == nil) // binary plist
            plist = [self outputFor:@"/bin/sh -c /usr/bin/unzip__-p__%@__iTunesMetadata.plist__|__plutil__-convert__xml1__-o__-__-", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"\\__"]];
        NSDictionary *metadata = [plist propertyList];
        NSString *name = metadata[@"itemName"];
        GPackage *pkg = [[GPackage alloc] initWithName:name
                                               version:@""
                                                system:self
                                                status:GUpToDateStatus];
        pkg.ID = [filename substringToIndex:[filename length] - 4];
        pkg.installed = version;
        pkg.categories = metadata[@"genre"];
        [pkgs addObject:pkg];
    }
    //    for (GPackage *pkg in self.installed) {
    //        ((GPackage *)[self.index objectForKey:[pkg key]]).status = pkg.status;
    //    }
    return pkgs;
}

- (NSArray *)outdated {
    NSMutableArray *pkgs = [NSMutableArray array];
    // TODO:
    return pkgs;
}

- (NSArray *)inactive {
    NSMutableArray *pkgs = [NSMutableArray array];
    //    for (GPackage *pkg in [self installed]) {
    //        if (pkg.status == GInactiveStatus)
    //            [pkgs addObject:pkg];
    //    }
    return pkgs;
}


// TODO:
- (NSString *)info:(GItem *)item {
    return [self cat:item];
    
}

- (NSString *)home:(GItem *)item {
    NSString *homepage = self.homepage;
    NSString *ipa = [[NSString stringWithFormat:@"~/Music/iTunes/iTunes Media/Mobile Applications/%@.ipa", item.ID] stringByExpandingTildeInPath];
    NSString *plist = [self outputFor:@"/usr/bin/unzip -p %@ iTunesMetadata.plist", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"__"]];
    if (plist == nil) // binary plist
        plist = [self outputFor:@"/bin/sh -c /usr/bin/unzip__-p__%@__iTunesMetadata.plist__|__plutil__-convert__xml1__-o__-__-", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"\\__"]];
    NSDictionary *metadata = [plist propertyList];
    NSNumber *itemId = metadata[@"itemId"];
    id mainDiv =[self.agent nodesForURL:[NSString stringWithFormat:@"http://itunes.apple.com/app/id%@",itemId] XPath:@"//div[@id=\"main\"]"][0];
    NSArray *links = mainDiv[@"//div[@class=\"app-links\"]/a"];
    // TODO: get screenshots via JSON
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
    homepage = [links[0] href];
    if ([homepage is:@"http://"])
        homepage = [links[1] href];
    return homepage;
}

- (NSString *)log:(GItem *)item {
    if (item == nil ) {
        return self.homepage;
    } else {
        NSString *ipa = [[NSString stringWithFormat:@"~/Music/iTunes/iTunes Media/Mobile Applications/%@.ipa", item.ID] stringByExpandingTildeInPath];
        NSString *plist = [self outputFor:@"/usr/bin/unzip -p %@ iTunesMetadata.plist", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"__"]];
        if (plist == nil) // binary plist
            plist = [self outputFor:@"/bin/sh -c /usr/bin/unzip__-p__%@__iTunesMetadata.plist__|__plutil__-convert__xml1__-o__-__-", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"\\__"]];
        NSDictionary *metadata = [plist propertyList];
        NSNumber *itemId = metadata[@"itemId"];
        return [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", itemId];
    }
}

- (NSString *)contents:(GItem *)item {
    NSString *ipa = [[[NSString stringWithFormat:@"~/Music/iTunes/iTunes Media/Mobile Applications/%@.ipa", item.ID] stringByExpandingTildeInPath] stringByReplacingOccurrencesOfString:@" " withString:@"__"];
    NSString *output = [self outputFor:@"/usr/bin/zipinfo -1 %@", ipa];
    return output;
}

- (NSString *)cat:(GItem *)item {
    NSString *ipa = [[NSString stringWithFormat:@"~/Music/iTunes/iTunes Media/Mobile Applications/%@.ipa", item.ID] stringByExpandingTildeInPath];
    NSString *plist = [self outputFor:@"/usr/bin/unzip -p %@ iTunesMetadata.plist", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"__"]];
    if (plist == nil) // binary plist
        plist = [self outputFor:@"/bin/sh -c /usr/bin/unzip__-p__%@__iTunesMetadata.plist__|__plutil__-convert__xml1__-o__-__-", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"\\__"]];
    NSDictionary *metadata = [plist propertyList];
    return [metadata description];
}


- (NSArray *)availableCommands {
    return [super availableCommands];
}


@end
