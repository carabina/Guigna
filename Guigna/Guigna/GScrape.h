#import "GSource.h"
#import "GItem.h"

#import "GAgent.h"

@interface GScrape : GSource

@property(assign) NSInteger pageNumber;
@property(assign) NSInteger itemsPerPage;

- (instancetype)initWithName:(NSString *)name agent:(GAgent *)agent;
- (void)refresh;

@end
