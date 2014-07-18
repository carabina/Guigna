#import "GAdditions.h"
#import "GSource.h"

#import "GItem.h"

@implementation GSource

- (instancetype)initWithName:(NSString *)name agent:(GAgent *)agent {
    self = [super init];
    if (self) {
        _name = [name copy];
        _agent = agent;
        _items = [NSMutableArray array];
        _status = GOnState;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name {
    self = [self initWithName:name agent:nil];
    return self;
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [self initWithName:@"" agent:agent];
    return self;
}

- (NSString *)info:(GItem *)item {
    return [NSString stringWithFormat:@"%@ - %@\n%@", item.name, item.version, [self home:item]];
}

- (NSString *)home:(GItem *)item {
    if (item.homepage != nil)
        return item.homepage;
    else
        return self.homepage;
}

- (NSString *)log:(GItem *)item {
    return [self home:item];
}

- (NSString *)contents:(GItem *)item {
    return @"";
}

- (NSString *)cat:(GItem *)item {
    return @"[Not available]";
}

- (NSString *)deps:(GItem *)item {
    return @"";
}

- (NSString *)dependents:(GItem *)item {
    return @"";
}

@end


@implementation GSourceTransformer

+ (Class)transformedValueClass {
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

- (id)transformedValue:(GSource *)source {
    NSString *name = source.name;
    if ([name is:@"MacPorts"])
        return [NSImage imageNamed:@"system-macports.tiff"];
    else if ([name is:@"Homebrew"])
        return [NSImage imageNamed:@"system-homebrew.tiff"];
    else if ([name is:@"Homebrew Casks"])
        return [NSImage imageNamed:@"system-homebrewcasks.tiff"];
    else if ([name is:@"Mac OS X"])
        return [NSImage imageNamed:@"system-macosx.tiff"];
    else if ([name is:@"iTunes"])
        return [NSImage imageNamed:@"system-itunes.tiff"];
    else if ([name is:@"Fink"])
        return [NSImage imageNamed:@"system-fink.tiff"];
    else if ([name is:@"pkgsrc"])
        return [NSImage imageNamed:@"system-pkgsrc.tiff"];
    else if ([name is:@"FreeBSD"])
        return [NSImage imageNamed:@"source-freebsd.tiff"];
    else if ([name is:@"Rudix"])
        return [NSImage imageNamed:@"system-rudix.tiff"];
    else if ([name is:@"Native Installers"])
        return [NSImage imageNamed:@"source-native.tiff"];
    else if ([name is:@"PyPI"])
        return [NSImage imageNamed:@"source-pypi.tiff"];
    else if ([name is:@"RubyGems"])
        return [NSImage imageNamed:@"source-rubygems.tiff"];
    else if ([name is:@"CocoaPods"])
        return [NSImage imageNamed:@"source-cocoapods.tiff"];
    else if ([name is:@"Debian"])
        return [NSImage imageNamed:@"source-debian.tiff"];
    else if ([name is:@"Freecode"])
        return [NSImage imageNamed:@"source-freecode.tiff"];
    else if ([name is:@"Pkgsrc.se"])
        return [NSImage imageNamed:@"source-pkgsrc.se.tiff"];
    else if ([name is:@"AppShopper"])
        return [NSImage imageNamed:@"source-appshopper.tiff"];
    else if ([name is:@"AppShopper iOS"])
        return [NSImage imageNamed:@"source-appshopper.tiff"];
    else if ([name is:@"MacUpdate"])
        return [NSImage imageNamed:@"source-macupdate.tiff"];
    else if ([name is:@"installed"])
        return [NSImage imageNamed:NSImageNameStatusAvailable];
    else if ([name is:@"outdated"])
        return [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
    else if ([name is:@"inactive"])
        return [NSImage imageNamed:NSImageNameStatusNone];
    else if ([name hasPrefix:@"marked"])
        return [NSImage imageNamed:@"status-marked.tiff"];
    else if ([name hasPrefix:@"updated"])
        return [NSImage imageNamed:@"status-updated.tiff"];
    else if ([name hasPrefix:@"new"])
        return [NSImage imageNamed:@"status-new.tiff"];
    
    else
        return nil;
}

@end

