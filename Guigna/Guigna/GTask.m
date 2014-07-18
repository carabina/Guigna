#import "GTask.h"

@implementation GTask


- (instancetype)initWithItem:(GItem *)item {
    self = [super init];
    if (self) {
        _item = item;
    }
    return self;
}

- (GMark)mark {
    return self.item.mark;
}

- (GSystem *)system {
    return self.item.system;
}

@end
