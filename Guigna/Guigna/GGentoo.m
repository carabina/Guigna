#import "GGentoo.h"
#import "GPackage.h"


@implementation GGentoo

+ (NSString *)prefix {
    return [@"~/Gentoo" stringByExpandingTildeInPath];
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Gentoo" agent:agent];
    if (self) {
        self.homepage = @"http://www.gentoo.org/proj/en/gentoo-alt/prefix/";
        self.cmd = [NSString stringWithFormat:@"%@/bin/emerge", self.prefix];
    }
    return self;
}


// TODO: 
- (NSString *)log:(GItem *)item {
    return @"http://packages.gentoo.org/arch/x64-macos?arches=all";
}

+ (NSString *)setupCmd {
    return @"sudo mv /usr/local /usr/local_off ; sudo mv /opt/local /opt/local_off ; sudo mv /sw /sw_off ; cd ~/Library/Application\\ Support/Guigna/Gentoo ; curl -L http://overlays.gentoo.org/proj/alt/browser/trunk/prefix-overlay/scripts/bootstrap-prefix.sh?format=txt -o bootstrap-prefix.sh ; chmod 755 bootstrap-prefix.sh ; ./bootstrap-prefix.sh ; sudo mv /usr/local_off /usr/local ; sudo mv /opt/local_off /opt/local ; sudo mv /sw_off /sw";
}

@end
