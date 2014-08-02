#import "GGtkOSX.h"
#import "GPackage.h"


@implementation GGtkOSX

+ (NSString *)prefix {
    return [@"~/.local" stringByExpandingTildeInPath];
}

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Gtk-OSX" agent:agent];
    if (self) {
        self.homepage = @"http://live.gnome.org/GTK%2B/OSX";
        self.cmd = [NSString stringWithFormat:@"%@/bin/jhbuild", self.prefix];
    }
    return self;
}


// TODO: 
- (NSString *)log:(GItem *)item {
    return @"http://git.gnome.org/browse/gtk-osx/";
}


- (NSArray *)availableCommands {
    return [super availableCommands];
}


// TODO: test

+ (NSString *)setupCmd {
    return @"sudo mv /usr/local /usr/local_off ; sudo mv /opt/local /opt/local_off ; sudo mv /sw /sw_off ; cd ~/Library/Application\\ Support/Guigna/ ; curl -L -O http://git.gnome.org/browse/gtk-osx/plain/gtk-osx-build-setup.sh ; sh gtk-osx-build-setup.sh ; ~/.local/bin/jhbuild bootstrap ; ~/.local/bin/jhbuild build meta-gtk-osx-bootstrap ; ~/.local/bin/jhbuild build meta-gtk-osx-core ; ~/.local/bin/jhbuild shell ; sudo mv /usr/local_off /usr/local ; sudo mv /opt/local_off /opt/local ; sudo mv /sw_off /sw";
}

+ (NSString *)removeCmd {
    return @"rm -rf ~/gtk ; rm -rf ~/.local ; rm ~/.jhbuildrc*";
}

@end
