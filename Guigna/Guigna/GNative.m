#import "GNative.h"
#import "GAdditions.h"

@implementation GNative

- (instancetype)initWithAgent:(GAgent *)agent {
    self = [super initWithName:@"Native Installers" agent:agent];
    if (self) {
        self.homepage = @"http://github.com/gui-dos/Guigna/";
        self.itemsPerPage = 250;
        self.cmd = @"installer";
    }
    return self;
}

- (void) refresh {
    NSMutableArray *pkgs = [NSMutableArray array];
    NSString *url = @"https://docs.google.com/spreadsheet/ccc?key=0AryutUy3rKnHdHp3MFdabGh6aFVnYnpnUi1mY2E2N0E";
    NSArray *nodes = [self.agent nodesForURL:url XPath:@"//table[@id=\"tblMain\"]//tr"];
    for (id node in nodes) {
        if ([node[@"@class"] is:@"rShim"])
            continue;
        NSArray *columns = node[@"td"];
        NSString *name = [columns[1] stringValue];
        NSString *version = [columns[2] stringValue];
        NSString *homepage = [columns[4] stringValue];
        NSString *URL = [columns[5] stringValue];
        GItem *pkg = [[GItem alloc] initWithName:name
                                          version:version
                                           source:self
                                           status:GAvailableStatus];
        pkg.homepage = homepage;
        pkg.description = URL;
        pkg.URL = URL;
        [pkgs addObject:pkg];
    }
    self.items = pkgs;
}

@end
