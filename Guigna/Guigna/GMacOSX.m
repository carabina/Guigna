#import "GMacOSX.h"
#import "GPackage.h"
#import "GAdditions.h"

@implementation GMacOSX

+ (NSString *)prefix {
    return @"/usr/sbin";
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Mac OS X" agent:agent];
    if (self) {
        self.homepage = @"http://support.apple.com/downloads/";
        self.cmd = [NSString stringWithFormat:@"%@/pkgutil", self.prefix];
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
    NSMutableArray *pkgs = [NSMutableArray array];
    NSMutableArray *pkgIds = [NSMutableArray arrayWithArray:[[self outputFor: @"/usr/sbin/pkgutil --pkgs"] split:@"\n"]];
    [pkgIds removeLastObject];
    NSArray *history = [[[NSArray arrayWithContentsOfFile:@"/Library/Receipts/InstallHistory.plist"] reverseObjectEnumerator] allObjects];
    BOOL keepPkg;
    for (NSDictionary *dict in history) {
        keepPkg = NO;
        NSArray *ids = dict[@"packageIdentifiers"];
        for (NSString *pkgId in ids) {
            if ([pkgIds indexOfObject:pkgId] != NSNotFound) {
                keepPkg = YES;
                [pkgIds removeObject:pkgId];
            }
        }
        if (!keepPkg)
            continue;
        NSString *name = dict[@"displayName"];
        NSString *version = dict[@"displayVersion"];
        NSString *category = [[dict[@"processName"] stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
        if ([category is:@"installer"]) {
            version = [[self outputFor: @"/usr/sbin/pkgutil --pkg-info-plist %@", ids[0]] propertyList][@"pkg-version"];
        }
        GPackage *pkg = [[GPackage alloc] initWithName:name
                                               version:nil
                                                system:self
                                                status:GUpToDateStatus];
        pkg.ID = [ids join];
        pkg.categories = category;
        pkg.description = pkg.ID;
        pkg.installed = version; // TODO: pkg.version;
        [pkgs addObject:pkg];
    }
    //    for (GPackage *pkg in self.installed) {
    //        ((GPackage *)[self.index objectForKey:[pkg key]]).status = pkg.status;
    //    }
    return pkgs;
}

- (NSArray *)outdated {
    NSMutableArray *pkgs = [NSMutableArray array];
    // TODO: sudo /usr/sbin/softwareupdate --list
    return pkgs;
}

- (NSArray *)inactive {
    NSMutableArray *pkgs = [NSMutableArray array];
    for (GPackage *pkg in [self installed]) {
        if (pkg.status == GInactiveStatus)
            [pkgs addObject:pkg];
    }
    return pkgs;
}


- (NSString *)info:(GItem *)item {
    NSMutableString *output = [NSMutableString string];
    for (NSString *pkgID in [item.ID split]) {
        [output appendString:[self outputFor: @"/usr/sbin/pkgutil --pkg-info %@", pkgID]];
        [output appendString:@"\n"];
    }
    return output;
}


- (NSString *)home:(GItem *)item {
    NSString *homepage = @"http://support.apple.com/downloads/";
    if ([item.categories is:@"storeagent"] || [item.categories is:@"storedownloadd"]) {
        NSString *url = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", item.ID];
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        NSArray *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil][@"results"];
        if ([results count] > 0) {
            NSString *pkgID = [results[0][@"trackId"] stringValue];
            id mainDiv =[self.agent nodesForURL:[@"http://itunes.apple.com/app/id" stringByAppendingString:pkgID] XPath:@"//div[@id=\"main\"]"][0];
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
        }
    }
    return homepage;
}

- (NSString *)log:(GItem *)item {
    NSString *page = @"http://support.apple.com/downloads/";
    if (item != nil ) {
        if ([item.categories is:@"storeagent"] || [item.categories is:@"storedownloadd"]) {
            NSString *url = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", item.ID];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            NSArray *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil][@"results"];
            if ([results count] > 0) {
                NSString *pkgID = [results[0][@"trackId"] stringValue];
                page = [@"http://itunes.apple.com/app/id" stringByAppendingString:pkgID];
            }
        }
    }
    return page;
}

- (NSString *)contents:(GItem *)item {
    NSMutableString *contents = [NSMutableString string];
    for (NSString *pkgID in [item.ID split]) {
        NSDictionary *plist = [[self outputFor:@"%@ --pkg-info-plist %@", self.cmd, pkgID] propertyList];
        NSMutableArray *files = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ --files %@", self.cmd, pkgID] split:@"\n"]];
        [files removeLastObject];
        for (NSString *file in files) {
            [contents appendString:[NSString pathWithComponents:@[plist[@"volume"], plist[@"install-location"], file]]];
            [contents appendString:@"\n"];
        }
    }
    return contents;
}

- (NSString *)cat:(GItem *)item {
    return @"TODO";
}


- (NSArray *)availableCommands {
    return [super availableCommands];
}


- (NSString *)uninstallCmd:(GPackage *)pkg {
    // SEE: https://github.com/caskroom/homebrew-cask/blob/master/lib/cask/pkg.rb
    NSMutableArray *commands = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *dirsToDelete = [NSMutableArray array];
    BOOL isDir;
    for (NSString *pkgID in [pkg.ID split]) {
        NSDictionary *plist = [[self outputFor:@"%@ --pkg-info-plist %@", self.cmd, pkgID] propertyList];
        NSMutableArray *dirs = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ --only-dirs --files %@", self.cmd, pkgID] split:@"\n"]];
        [dirs removeLastObject];
        for (NSString *dir in dirs) {
            NSString *dirPath = [NSString pathWithComponents:@[plist[@"volume"], plist[@"install-location"], dir]];
            NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:dirPath error:nil];
            if ((![[fileAttributes fileOwnerAccountID] isEqual:@0] && ![dirPath hasPrefix:@"/usr/local"])
                || [dirPath contains:pkg.name]
                || [dirPath contains:@"."]
                || [dirPath hasPrefix:@"/opt/"]) {
                if ([[dirsToDelete filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%@ CONTAINS SELF", dirPath]] count] == 0) {
                    [dirsToDelete addObject:dirPath];
                    [commands addObject:[NSString stringWithFormat:@"sudo rm -r \"%@\"", dirPath]];
                }
            }
        }
        NSMutableArray *files = [NSMutableArray arrayWithArray:[[self outputFor:@"%@ --files %@", self.cmd, pkgID] split:@"\n"]]; // links are not detected with --only-files
        [files removeLastObject];
        for (NSString *file in files) {
            NSString *filePath = [NSString pathWithComponents:@[plist[@"volume"], plist[@"install-location"], file]];
            if (!([fileManager fileExistsAtPath:filePath isDirectory:&isDir] && isDir)) {
                if ([[dirsToDelete filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%@ CONTAINS SELF", filePath]] count] == 0)
                    [commands addObject:[NSString stringWithFormat:@"sudo rm \"%@\"", filePath]];
            }
        }
        
        [commands addObject:[NSString stringWithFormat:@"sudo %@ --forget %@", self.cmd, pkgID]];
    }
    return [commands join:@" ; "];
	
    // TODO: disable Launchd daemons, clean Application Support, Caches, Preferences
    // SEE: https://github.com/caskroom/homebrew-cask/blob/master/lib/cask/artifact/pkg.rb
}

@end
