#import "GLibrary.h"
#import "GAdditions.h"


@implementation G

+ (NSString *)OSVersion {
    NSString *versionString = [[NSProcessInfo processInfo] operatingSystemVersionString];
    return versionString.split[1];
}

@end
