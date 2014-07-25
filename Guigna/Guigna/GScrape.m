#import "GScrape.h"

@implementation GScrape


- (instancetype)initWithName:(NSString *)name agent:(GAgent *)agent {
    self = [super initWithName:name agent:agent];
    _pageNumber = 1;
    return self;
}

- (void)refresh {
}

@end
