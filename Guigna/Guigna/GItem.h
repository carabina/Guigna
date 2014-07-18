#import <Foundation/Foundation.h>

#import "GSource.h"

@class GSystem;


typedef NS_ENUM(NSInteger, GStatus) {
    GAvailableStatus = 0,
    GInactiveStatus,
    GUpToDateStatus,
    GOutdatedStatus,
    GUpdatedStatus,
    GNewStatus,
    GBrokenStatus
};

typedef NS_ENUM(NSInteger, GMark) {
    GNoMark = 0,
    GInstallMark= 1,
    GUninstallMark,
    GDeactivateMark,
    GUpgradeMark,
    GFetchMark,
    GCleanMark
};


@interface GItem : NSObject  <NSCoding>

@property(strong) NSString *name;
@property(strong) NSString *version;
@property(strong) NSString *installed;
@property(weak) GSource  *source;
@property(assign) GStatus status;
@property(weak) GSystem *system;
@property(assign) GMark mark;
@property(strong) NSString *ID;
@property(strong) NSString *categories;
@property(strong) NSString *description;
@property(strong) NSString *homepage;
@property(strong) NSString *screenshots;
@property(strong) NSString *URL;
@property(strong) NSString *date;
@property(strong) NSString *license;


- (instancetype)initWithName:(NSString *)name
           version:(NSString *)version
            source:(GSource *)source
            status:(GStatus)status;

- (NSString *)info;
- (NSString *)home;
- (NSString *)log;
- (NSString *)contents;
- (NSString *)cat;
- (NSString *)deps;
- (NSString *)dependents;

@end


@interface GStatusTransformer : NSValueTransformer
@end

@interface GMarkTransformer : NSValueTransformer
@end

