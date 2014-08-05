#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import <ScriptingBridge/ScriptingBridge.h>
#import "Terminal.h"
#import "Safari.h"

#import "GAdditions.h"
#import "GAgent.h"

#import "GItem.h"
#import "GSource.h"

#import "GMacPorts.h"
#import "GHomebrew.h"
#import "GHomebrewCasks.h"
#import "GFink.h"
#import "GMacOSX.h"
#import "GITunes.h"
#import "GPkgsrc.h"
#import "GFreeBSD.h"
#import "GGtkOSX.h"
#import "GGentoo.h"
#import "GNative.h"
#import "GRudix.h"
#import "GPyPI.h"
#import "GRubyGems.h"
#import "GCocoaPods.h"
#import "GFreecode.h"
#import "GDebian.h"
#import "GPkgsrcSE.h"
#import "GAppShopper.h"
#import "GAppShopperIOS.h"
#import "GMacUpdate.h"

@interface GuignaAppDelegate : NSObject <GAppDelegate, NSApplicationDelegate, NSMenuDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, NSTableViewDelegate, NSTableViewDataSource, NSTextViewDelegate>

@property (strong) IBOutlet GAgent *agent;
@property (strong) IBOutlet NSUserDefaultsController *defaults;

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSOutlineView *sourcesOutline;
@property (strong) IBOutlet NSTableView *itemsTable;
@property (strong) IBOutlet NSSearchField *searchField;
@property (strong) IBOutlet NSTabView *tabView;
@property (strong) IBOutlet NSTextView *infoText;
@property (strong) IBOutlet WebView *webView;
@property (strong) IBOutlet NSTextView *logText;
@property (strong) IBOutlet NSSegmentedControl *segmentedControl;
@property (strong) IBOutlet NSPopUpButton *commandsPopUp;
@property (strong) IBOutlet NSButton *shellDisclosure;
@property (strong) IBOutlet NSTextField *cmdline;
@property (strong) IBOutlet NSTextField *statusField;
@property (strong) IBOutlet NSButton *clearButton;
@property (strong) IBOutlet NSButton *screenshotsButton;
@property (strong) IBOutlet NSButton *moreButton;
@property (strong) IBOutlet NSTextField *statsLabel;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSProgressIndicator *tableProgressIndicator;
@property (strong) IBOutlet NSToolbarItem *applyButton;
@property (strong) IBOutlet NSToolbarItem *stopButton;
@property (strong) IBOutlet NSToolbarItem *syncButton;

@property (strong) IBOutlet NSStatusItem *statusItem;
@property (strong) IBOutlet NSMenu *statusMenu;
@property (strong) IBOutlet NSMenu *toolsMenu;
@property (strong) IBOutlet NSMenu *markMenu;

@property (strong) IBOutlet NSPanel *optionsPanel;
@property (strong) IBOutlet NSProgressIndicator *optionsProgressIndicator;
@property (strong) IBOutlet NSTextField *optionsStatusField;
@property (strong) IBOutlet NSSegmentedControl *themesSegmentedControl;

@property(strong) TerminalApplication *terminal;
@property(strong) TerminalTab *shell;
@property(strong) TerminalWindow *shellWindow;
@property(strong) SafariApplication *browser;

@property (strong) IBOutlet NSTreeController *sourcesController;
@property (strong) IBOutlet NSArrayController *itemsController;

@property(strong) NSMutableArray *sources;
@property(strong) NSMutableArray *systems;
@property(strong) NSMutableArray *scrapes;
@property(strong) NSMutableArray *repos;

@property(strong) NSMutableArray *items;
@property(strong) NSMutableArray *allPackages;
@property(strong) NSMutableDictionary *packagesIndex;
@property(strong) NSMutableArray *markedItems;

@property(assign) NSInteger marksCount;
@property(strong) NSString *selectedSegment;
@property(assign) NSInteger previousSegment;
@property(strong) NSString *APPDIR;

@property(strong) NSFont *tableFont;
@property(strong) NSColor *tableTextColor;
@property(strong) NSColor *logTextColor;
@property(strong) NSDictionary *linkTextAttributes;
@property(strong) NSColor *sourceListBackgroundColor;

@property(strong) NSString *adminPassword;
@property(strong) NSTimer *minuteTimer;
@property(assign) BOOL ready;


- (void)status:(NSString *)msg;
- (void)info:(NSString *)msg;
- (void)log:(NSString *)text;

- (NSInteger)shellColumns;

- (void)sourcesSelectionDidChange:(id)sender;
- (void)updateTabView:(GItem *)item;
- (void)updateScrape:(GScrape *)scrape;
- (void)updateCmdLine:(NSString *)cmd;
- (void)execute:(NSString *)cmd withBaton:(NSString *)baton;
- (void)execute:(NSString *)cmd;
- (void)executeAsRoot:(NSString *)cmd;
- (void)sudo:(NSString *)cmd withBaton:(NSString *)baton;
- (void)sudo:(NSString *)cmd;

- (void)reloadAllPackages;
- (void)sync:(id)sender;
- (void)updateMarkedSource;

- (IBAction)marks:(id)sender;
- (IBAction)apply:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)syncAction:(id)sender;
- (IBAction)details:(id)sender;
- (IBAction)raiseBrowser:(id)sender;
- (IBAction)raiseShell:(id)sender;
- (IBAction)open:(id)sender;
- (IBAction)toolsAction:(id)sender;
- (IBAction)options:(id)sender;
- (IBAction)preferences:(id)sender;

- (IBAction)search:(id)sender;
- (IBAction)executeCommandsMenu:(id)sender;

- (IBAction)switchSegment:(id)sender;
- (IBAction)toggleShell:(id)sender;
- (IBAction)executeCmdLine:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)toggleScreenshots:(id)sender;
- (IBAction)moreScrapes:(id)sender;
- (IBAction)showMarkMenu:(id)sender;
- (IBAction)mark:(id)sender;
- (IBAction)closeOptions:(id)sender;
- (IBAction)tools:(id)sender;


@end


@interface GDefaultsTransformer : NSValueTransformer
@end
