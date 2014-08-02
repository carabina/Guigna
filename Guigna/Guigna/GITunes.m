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
        NSUInteger sep = [filename rangeOfString:@" " options:NSBackwardsSearch].location;
        if (sep == NSNotFound)
            continue;
        NSString *version = [filename substringWithRange:NSMakeRange(sep+1, [filename length]-sep-5)];
        NSString *output = [self outputFor:@"/usr/bin/unzip -p %@ iTunesMetadata.plist", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"__"]];
        if (output == nil) // binary plist
            output = [self outputFor:@"/bin/sh -c /usr/bin/unzip__-p__%@__iTunesMetadata.plist__|__plutil__-convert__xml1__-o__-__-", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"\\__"]];
        NSDictionary *metadata = [NSPropertyListSerialization propertyListWithData:[output dataUsingEncoding:NSUTF8StringEncoding] options:NSPropertyListImmutable format:NULL error:nil];
        NSString *name = metadata[@"itemName"];
        GPackage *pkg = [[GPackage alloc] initWithName:name
                                               version:@""
                                                system:self
                                                status:GUpToDateStatus];
        pkg.ID = [filename substringToIndex:[filename length]-4];
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
    NSString *ipa = [[NSString stringWithFormat:@"~/Music/iTunes/iTunes Media/Mobile Applications/%@.ipa", item.ID] stringByExpandingTildeInPath];
    NSString *output = [self outputFor:@"/usr/bin/unzip -p %@ iTunesMetadata.plist", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"__"]];
    if (output == nil) // binary plist
        output = [self outputFor:@"/bin/sh -c /usr/bin/unzip__-p__%@__iTunesMetadata.plist__|__plutil__-convert__xml1__-o__-__-", [ipa stringByReplacingOccurrencesOfString:@" " withString:@"\\__"]];
    NSDictionary *metadata = [NSPropertyListSerialization propertyListWithData:[output dataUsingEncoding:NSUTF8StringEncoding] options:NSPropertyListImmutable format:NULL error:nil];
    return [metadata description];
    
}

// TODO: macappstore://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%@&mt=12

- (NSString *)log:(GItem *)item {
    return @"https://itunes.apple.com/genre/ios/id36?mt=8";
}

- (NSString *)contents:(GItem *)item {
    NSString *ipa = [[[NSString stringWithFormat:@"~/Music/iTunes/iTunes Media/Mobile Applications/%@.ipa", item.ID] stringByExpandingTildeInPath] stringByReplacingOccurrencesOfString:@" " withString:@"__"];
    NSString *output = [self outputFor:@"/usr/bin/zipinfo -1 %@", ipa];
    return output;
}

- (NSString *)cat:(GItem *)item {
    return @"TODO";
}


- (NSArray *)availableCommands {
    return [super availableCommands];
}


@end
