#import "GItem.h"

#import "GAdditions.h"

@implementation GItem

@synthesize description;

- (instancetype)initWithName:(NSString *)name
           version:(NSString *)version
            source:(GSource *)source
            status:(GStatus)status {
    self = [super init];
    if (self) {
        _name = [name copy];
        _version = [version copy];
        _source = source;
        _status = status;
    }
    return self;
}

// TODO:

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self) {
		_name = [coder decodeObjectForKey:@"name"];
		_version = [coder decodeObjectForKey:@"version"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_version forKey:@"version"];
}


- (NSString *)info {
    return [self.source info:self];
}

- (NSString *)home {
    return [self.source home:self];
}

- (NSString *)log {
    return [self.source log:self];
}

- (NSString *)contents {
    return [self.source contents:self];
}

- (NSString *)cat {
    return [self.source cat:self];
}

- (NSString *)deps {
    return [self.source deps:self];
}

- (NSString *)dependents {
    return [self.source dependents:self];
}


@end


@implementation GStatusTransformer

+ (Class)transformedValueClass {
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

- (id)transformedValue:(id)status {
    switch ([status intValue]) {
        case GInactiveStatus:
            return [NSImage imageNamed:NSImageNameStatusNone];
            break;
        case GUpToDateStatus:
            return [NSImage imageNamed:NSImageNameStatusAvailable];
            break;
        case GOutdatedStatus:
            return [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
            break;
        case GUpdatedStatus:
            return [NSImage imageNamed:@"status-updated.tiff"];
            break;
        case GNewStatus:
            return [NSImage imageNamed:@"status-new.tiff"];
            break;
        case GBrokenStatus:
            return [NSImage imageNamed:NSImageNameStatusUnavailable];
            break;
        default:
            return nil;
    }
}

@end


@implementation GMarkTransformer

+ (Class)transformedValueClass {
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

- (id)transformedValue:(id)mark {
    switch ([mark intValue]) {
        case GInstallMark:
            return [NSImage imageNamed:NSImageNameAddTemplate];
            break;
        case GUninstallMark:
            return [NSImage imageNamed:NSImageNameRemoveTemplate];
            break;
        case GDeactivateMark:
            return [NSImage imageNamed:NSImageNameStopProgressTemplate];
            break;
        case GUpgradeMark:
            return [NSImage imageNamed:NSImageNameRefreshTemplate];
            break;
        case GFetchMark:
            return [NSImage imageNamed:@"source-native.tiff"];
            break;
        case GCleanMark:
            return [NSImage imageNamed:NSImageNameActionTemplate];
            break;
        default:
            return nil;
    }
}

@end
