#import "GuignaAppDelegate.h"
#import "GAdditions.h"


@implementation GuignaAppDelegate

@synthesize agent, defaults;
@synthesize window = _window;
@synthesize sourcesOutline, itemsTable, searchField;
@synthesize tabView, infoText, webView, logText;
@synthesize segmentedControl, commandsPopUp, shellDisclosure, cmdline;
@synthesize statusField, clearButton, screenshotsButton, moreButton, statsLabel;
@synthesize progressIndicator, tableProgressIndicator;
@synthesize applyButton, stopButton, syncButton;
@synthesize statusItem, statusMenu, toolsMenu, markMenu;
@synthesize optionsPanel, optionsProgressIndicator, optionsStatusField, themesSegmentedControl;
@synthesize terminal, shell, shellWindow, browser;
@synthesize sourcesController, itemsController;
@synthesize sources, systems, scrapes, repos;
@synthesize items, allPackages, packagesIndex, markedItems;
@synthesize marksCount, selectedSegment, previousSegment;
@synthesize APPDIR;
@synthesize tableFont, tableTextColor, logTextColor, linkTextAttributes, sourceListBackgroundColor;
@synthesize ready;


- (void)status:(NSString *)msg {
    if ([msg hasSuffix:@"..."]) {
        [progressIndicator startAnimation:self];
        if ([statusField.stringValue hasPrefix:@"Executing"])
            msg = [NSString stringWithFormat:@"%@ %@", statusField.stringValue, msg];
    }
    else {
        [progressIndicator stopAnimation:self];
        self.ready = YES;
    }
    [statusField setStringValue:msg];
    [statusField setToolTip:msg];
    [statusField display];
    if ([msg hasSuffix:@"..."])
        [statusItem setTitle:@"💤"];
    else
        [statusItem setTitle:@"😺"];
    [[statusMenu itemAtIndex:0] setTitle:msg];
    [statusItem setToolTip:msg];
}


- (void)info:(NSString *)text {
    infoText.string = text;
    [infoText scrollRangeToVisible:NSMakeRange(0,0)];
    [infoText display];
    [tabView display];
}


- (void)log:(NSString *)text {
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:text attributes:
                                  @{NSFontAttributeName: [NSFont fontWithName:@"Andale Mono" size:11.0],
                                    NSForegroundColorAttributeName:self.logTextColor}];
    NSTextStorage *storage = [logText textStorage];
    [storage beginEditing];
    [storage appendAttributedString:string];
    [storage endEditing];
    [logText display];
    [logText scrollRangeToVisible:NSMakeRange(logText.string.length, 0)];
    [tabView display];
}

- (NSInteger) shellColumns {
    NSDictionary *attrs = @{NSFontAttributeName: [NSFont fontWithName:@"Andale Mono" size:11.0]};
    CGFloat charWidth = ([@"MMM" sizeWithAttributes:attrs].width - [@"M" sizeWithAttributes:attrs].width) / 2;
    NSInteger columns = (int)round((infoText.frame.size.width - 16) / charWidth + 0.5);
    return columns;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [tableProgressIndicator startAnimation:self];
    
    GStatusTransformer *statusTransformer = [[GStatusTransformer alloc] init];
    [NSValueTransformer setValueTransformer:statusTransformer forName:@"StatusTransformer"];
    GSourceTransformer *sourceTransformer = [[GSourceTransformer alloc] init];
    [NSValueTransformer setValueTransformer:sourceTransformer forName:@"SourceTransformer"];
    GMarkTransformer *markTransformer = [[GMarkTransformer alloc] init];
    [NSValueTransformer setValueTransformer:markTransformer forName:@"MarkTransformer"];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setTitle:@"😺"];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:statusMenu];
    [itemsTable setDoubleAction:@selector(showMarkMenu:)];
    
    [infoText setFont:[NSFont fontWithName:@"Andale Mono" size:11.0]];
    [logText setFont: [NSFont fontWithName:@"Andale Mono" size:11.0]];
    NSString *welcomeMsg = @"\n\t\t\t\t\tWelcome to Guigna\n\t\tGUIGNA: the GUI of Guigna is Not by Apple  :)\n\n\t[Sync] to update from remote repositories.\n\tRight/double click a package to mark it.\n\t[Apply] to commit the changes to a [Shell].\n\n\tYou can try other commands typing in the yellow prompt.\n\tTip: Command-click to combine sources.\n\tWarning: keep the Guigna shell open!\n\n\n\t\t\t\tTHIS IS ONLY A PROTOTYPE.\n\n\n\t\t\t\tguido.soranzio@gmail.com";
    [self info:welcomeMsg];
    [infoText checkTextInDocument:nil];
    
    NSMenu *columnsMenu = [[NSMenu alloc] initWithTitle:@"ItemsColumnsMenu"];
    NSMenu *viewColumnsMenu = [[NSMenu alloc] initWithTitle:@"ItemsColumnsMenu"];
    for (NSMenu *menu in @[columnsMenu, viewColumnsMenu]) {
        for (NSTableColumn *column in itemsTable.tableColumns) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[column.headerCell stringValue]
                                                              action:@selector(toggleTableColumn:)
                                                       keyEquivalent:@""];
            menuItem.target = self;
            menuItem.representedObject = column;
            [menu addItem:menuItem];
        }
        menu.delegate = self;
    }
    [itemsTable.headerView setMenu:columnsMenu];
    NSMenuItem *viewMenu = [[NSApp mainMenu] itemWithTitle:@"View"];
    [[viewMenu submenu] addItem:[NSMenuItem separatorItem]];
    NSMenuItem *columnsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Columns" action:nil keyEquivalent:@ ""];
    [columnsMenuItem setSubmenu:viewColumnsMenu];
    [[viewMenu submenu] addItem:columnsMenuItem];
    
    agent = [[GAgent alloc] init];
    agent.appDelegate = self;
    
    sources = [[NSMutableArray alloc] init];
    systems = [[NSMutableArray alloc] init];
    scrapes = [[NSMutableArray alloc] init];
    repos = [[NSMutableArray alloc] init];
    items = [[NSMutableArray alloc] init];
    allPackages = [[NSMutableArray alloc] init];
    packagesIndex = [[NSMutableDictionary alloc] init];
    
    self.APPDIR = [@"~/Library/Application Support/Guigna" stringByExpandingTildeInPath];
    system([[NSString stringWithFormat: @"mkdir -p '%@'", self.APPDIR] UTF8String]);
    system([[NSString stringWithFormat: @"touch '%@/output'", self.APPDIR] UTF8String]);
    system([[NSString stringWithFormat: @"touch '%@/sync'", self.APPDIR] UTF8String]);
    for (NSString *dir in @[@"MacPorts", @"Homebrew", @"Fink", @"pkgsrc", @"FreeBSD", @"Gentoo"]) {
        system([[NSString stringWithFormat: @"mkdir -p '%@/%@'", self.APPDIR, dir] UTF8String]);
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    system("osascript -e 'tell application \"Terminal\" to close (windows whose name contains \"Guigna \")'");
    self.terminal = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
    NSString *guignaFunction = [NSString stringWithFormat:@"guigna() { osascript -e 'tell app \"Guigna\"' -e \"open POSIX file \\\"%@/$2\\\"\" -e 'end' &>/dev/null; }", self.APPDIR];
    NSString *initScript = [@"unset HISTFILE ; " stringByAppendingString:guignaFunction];
    self.shell = [self.terminal doScript:initScript in:nil];
    shell.customTitle = @"Guigna";
    for (TerminalWindow *window in terminal.windows) {
        if ([window.name contains:@"Guigna "])
            self.shellWindow = window;
    }
    self.sourceListBackgroundColor = [sourcesOutline backgroundColor];
    self.linkTextAttributes = [infoText linkTextAttributes];
    NSString *theme = defaults[@"Theme"];
    if (theme == nil || [theme is:@"Default"]) {
        shell.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.8 alpha:1.0]; // light yellow
        shell.normalTextColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        self.tableFont = [NSFont controlContentFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
        self.tableTextColor = [NSColor blackColor];
        self.logTextColor = [NSColor blackColor];
    } else {
        [themesSegmentedControl setSelectedSegment:[@[@"Default", @"Retro"] indexOfObject:theme]];
        [self applyTheme:theme];
    }
    
    NSDictionary *knownPaths = @{@"MacPorts": @"/opt/local", @"Homebrew": @"/usr/local", @"pkgsrc": @"/usr/pkg", @"Fink": @"/sw"};
    NSString *prefix;
    for (NSString *system in knownPaths.allKeys) {
        prefix = knownPaths[system];
        if ([fileManager fileExistsAtPath:[prefix stringByAppendingString:@"_off"]]) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert setMessageText:@"Hidden system detected."];
            [alert setInformativeText:[NSString stringWithFormat:@"The path to %@ is currently hidden by an \"_off\" suffix.", system]];
            [alert addButtonWithTitle:@"Unhide"];
            [alert addButtonWithTitle:@"Continue"];
            if ([alert runModal] == NSAlertFirstButtonReturn) {
                [self executeAsRoot:[NSString stringWithFormat:@"mv %@_off %@", prefix, prefix]];
            }
        }
    }
    
    NSString *portPath = [[GMacPorts prefix] stringByAppendingString:@"/bin/port"];
    NSString *brewPath = [[GHomebrew prefix] stringByAppendingString:@"/bin/brew"];
    NSArray *paths = [[agent outputForCommand:@"/bin/bash -l -c which__port__brew"] split:@"\n"];
    for (NSString *path in paths) {
        if ([path hasSuffix:@"port"]) {
            portPath = path;
        } else if ([path hasSuffix:@"brew"]) {
            brewPath = path;
        }
    }
    
    [self.terminal doScript:@"clear ; printf \"\\e[3J\" ; echo Welcome to Guigna! ; echo" in:self.shell];
    
    if ([fileManager fileExistsAtPath:portPath]
        || [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/MacPorts/PortIndex", self.APPDIR]]) {
        if (defaults[@"MacPortsStatus"] == nil)
            defaults[@"MacPortsStatus"] = @(GOnState);
        if (defaults[@"MacPortsParsePortIndex"] == nil)
            defaults[@"MacPortsParsePortIndex"] = @YES;
    }
    if ([defaults[@"MacPortsStatus"] isEqual:@(GOnState)]) {
        GSystem *macports = [[GMacPorts alloc] initWithAgent:self.agent];
        if (![fileManager fileExistsAtPath:portPath])
            macports.mode = GOnlineMode;
        if (!(macports.mode == GOnlineMode
              && ![fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/MacPorts/PortIndex", self.APPDIR]])) {
            [systems addObject:macports];
            if (![macports.cmd is:portPath]) {
                macports.prefix = [[portPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
                macports.cmd = portPath;
            }
        }
    }
    
    if ([fileManager fileExistsAtPath:brewPath]) {
        if (defaults[@"HomebrewStatus"] == nil)
            defaults[@"HomebrewStatus"] = @(GOnState);
    }
    if ([defaults[@"HomebrewStatus"] isEqual:@(GOnState)]) {
        if ([fileManager fileExistsAtPath:brewPath]) { // TODO: Online Mode
            GSystem *homebrew = [[GHomebrew alloc] initWithAgent:self.agent];
            [systems addObject:homebrew];
            if (![homebrew.cmd is:brewPath]) {
                homebrew.prefix = [[brewPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
                homebrew.cmd = brewPath;
            }
            if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/bin/brew-cask.rb", homebrew.prefix]]) {
                GSystem *homebrewcasks = [[GHomebrewCasks alloc] initWithAgent:self.agent];
                [systems addObject:homebrewcasks];
                homebrewcasks.prefix = homebrew.prefix;
                homebrewcasks.cmd = [brewPath stringByAppendingString:@" cask"];
            }
        }
    }
    
    if ([fileManager fileExistsAtPath:@"/sw/bin/fink"]) {
        if (defaults[@"FinkStatus"] == nil)
            defaults[@"FinkStatus"] = @(GOnState);
    }
    if ([defaults[@"FinkStatus"] isEqual:@(GOnState)]) {
        GSystem *fink = [[GFink alloc] initWithAgent:self.agent];
        if (![fileManager fileExistsAtPath:@"/sw/bin/fink"])
            fink.mode = GOnlineMode;
        [systems addObject:fink];
    }
    
    // TODO: Index user defaults
    if ([fileManager fileExistsAtPath:@"/usr/pkg/sbin/pkg_info"]
        || [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/pkgsrc/INDEX", self.APPDIR]]) {
        if (defaults[@"pkgsrcStatus"] == nil) {
            defaults[@"pkgsrcStatus"] = @(GOnState);
            defaults[@"pkgsrcCVS"] = @(GOnState);
        }
    }
    if ([defaults[@"pkgsrcStatus"] isEqual:@(GOnState)]) {
        GSystem *pkgsrc = [[GPkgsrc alloc] initWithAgent:self.agent];
        if (![fileManager fileExistsAtPath:@"/usr/pkg/sbin/pkg_info"])
            pkgsrc.mode = GOnlineMode;
        [systems addObject:pkgsrc];
    }
    
    if ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/FreeBSD/INDEX", self.APPDIR]]) {
        if (defaults[@"FreeBSDStatus"] == nil)
            defaults[@"FreeBSDStatus"] = @(GOnState);
    }
    if ([defaults[@"FreeBSDStatus"] isEqual:@(GOnState)]) {
        GSystem *freebsd = [[GFreeBSD alloc] initWithAgent:self.agent];
        freebsd.mode = GOnlineMode;
        [systems addObject:freebsd];
    }
    
    if ([fileManager fileExistsAtPath:@"/usr/local/bin/rudix"]) {
        if (defaults[@"RudixStatus"] == nil)
            defaults[@"RudixStatus"] = @(GOnState);
    }
    if ([defaults[@"RudixStatus"] isEqual:@(GOnState)]) {
        GSystem *rudix = [[GRudix alloc] initWithAgent:self.agent];
        if (![fileManager fileExistsAtPath:@"/usr/local/bin/rudix"])
            rudix.mode = GOnlineMode;
        [systems addObject:rudix];
    }
    
    GSystem *macosx = [[GMacOSX alloc] initWithAgent:self.agent];
    [systems addObject:macosx];
    
    if (defaults[@"iTunesStatus"] == nil)
        defaults[@"iTunesStatus"] = @(GOnState);
    if ([defaults[@"iTunesStatus"] isEqual:@(GOnState)]) {
        GSystem *itunes = [[GITunes alloc] initWithAgent:self.agent];
        [systems addObject:itunes];
    }
    
    
    if (defaults[@"ScrapesCount"] == nil)
        defaults[@"ScrapesCount"] = @15;
    
    GRepo *native = [[GNative alloc] initWithAgent:self.agent];
    [repos addObject:native];
    
    GScrape *pkgsrcse = [[GPkgsrcSE alloc] initWithAgent:self.agent];
    GScrape *freecode = [[GFreecode alloc] initWithAgent:self.agent];
    GScrape *debian = [[GDebian alloc] initWithAgent:self.agent];
    GScrape *cocoapods = [[GCocoaPods alloc] initWithAgent:self.agent];
    GScrape *pypi = [[GPyPI alloc] initWithAgent:self.agent];
    GScrape *rubygems = [[GRubyGems alloc] initWithAgent:self.agent];
    GScrape *appshopper = [[GAppShopper alloc] initWithAgent:self.agent];
    GScrape *macupdate = [[GMacUpdate alloc] initWithAgent:self.agent];
    GScrape *appshopperios = [[GAppShopperIOS alloc] initWithAgent:self.agent];
    [scrapes addObjectsFromArray:@[pkgsrcse, freecode, debian, cocoapods, pypi, rubygems, macupdate, appshopper, appshopperios]];
    
    GSource *source1 = [[GSource alloc] initWithName:@"SYSTEMS"];
    source1.categories = [[NSMutableArray alloc] init];
    [source1.categories addObjectsFromArray:systems];
    GSource *source2 = [[GSource alloc] initWithName:@"STATUS"];
    source2.categories = [[NSMutableArray alloc] init];
    [source2.categories addObjectsFromArray:@[[[GSource alloc] initWithName:@"installed"], [[GSource alloc] initWithName:@"outdated"], [[GSource alloc] initWithName:@"inactive"]]];
    GSource *source3 = [[GSource alloc] initWithName:@"REPOS"];
    source3.categories = [[NSMutableArray alloc] init];
    [source3.categories addObjectsFromArray:repos];
    GSource *source4 = [[GSource alloc] initWithName:@"SCRAPES"];
    source4.categories = [[NSMutableArray alloc] init];
    [source4.categories addObjectsFromArray:scrapes];
    [sourcesController setContent:[[NSMutableArray alloc] initWithObjects:source1, [[GSource alloc] initWithName:@""], source2, [[GSource alloc] initWithName:@""], source3, [[GSource alloc] initWithName:@""], source4, nil]];
    [sourcesOutline reloadData];
    [sourcesOutline expandItem:nil expandChildren:YES];
    [sourcesOutline display];
    
    self.browser =  [SBApplication applicationWithBundleIdentifier:@"com.apple.Safari"];
    selectedSegment = @"Info";
    
    [self performSelectorInBackground:@selector(reloadAllPackages) withObject:nil];
    
    _minuteTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(minuteCheck:) userInfo:nil repeats:YES];
    
    [applyButton setEnabled:NO];
    [stopButton setEnabled:NO];
    
    [self options:self];
}



- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.shellWindow != nil && [self.shellWindow.name contains:@"sudo"])
        [self raiseShell:self];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}


- (void)windowWillClose:(NSNotification *)notification {
    if (self.ready)
        system("osascript -e 'tell application \"Terminal\" to close (windows whose name contains \"Guigna \")'");
}


- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    return ![subview isEqualTo:[splitView subviews][0]];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    GSource *source = (GSource *)[item representedObject];
    return (source.categories != nil) && ![source isKindOfClass:[GSystem class]];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    GSource *source = (GSource *)[item representedObject];
    if (![[[item parentNode] representedObject] isKindOfClass:[GSource class]])
        return [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
    else {
        if (source.categories == nil && [[[item parentNode] representedObject] isKindOfClass:[GSystem class]])
            return [outlineView makeViewWithIdentifier:@"LeafCell" owner:self];
        else
            return [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    return [(GSource *)[item representedObject] isKindOfClass:[GSystem class]];
}


- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    [self status:@"Ready."];
    NSMutableString *history = [[self.shell history] mutableCopy];
    if (_adminPassword != nil) {
        NSString *sudoCommand = [NSString stringWithFormat:@"echo \"%@\" | sudo -S", _adminPassword];
        [history setString:[history stringByReplacingOccurrencesOfString:sudoCommand withString:@"sudo"]];
    }
    [history setString:[history stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    [self log:history]; [self log:@"\n"];
    [stopButton setEnabled:NO];
    [self status:@"Analyzing Shell output..."];
    if ([history hasSuffix:@"^C"]) { // TODO: || [history hasSuffix:@"Password:"]
        [segmentedControl setSelectedSegment:-1];
        [self updateTabView:nil];
        [self status:@"Shell: Interrupted."];
        [self updateMarkedSource];
        return YES;
    }
    NSUInteger idx = [history rindex:@"--->"]; // MacPorts
    NSUInteger idx2 = [history rindex:@"==>"]; // Homebrew
    // TODO ===> pkgsrc
    if (idx2 != NSNotFound && idx2 > idx)
        idx = idx2; // most recent system
    idx2 = [history rindex:@"guigna --baton"];
    if (idx2 != NSNotFound && idx != NSNotFound && idx2 > idx)
        idx = NSNotFound; // the last was a shell command
    if (idx == NSNotFound)
        idx = [history rindex:@"\n"];
    NSArray *lastLines = [[history substringFromIndex:idx] split:@"\n"];
    if ([lastLines count] > 1) {
        if ([lastLines[1] hasPrefix:@"Error"]) {
            [segmentedControl setSelectedSegment:-1];
            [self updateTabView:nil];
            [self updateMarkedSource];
            [self status:@"Shell: Error."];
            return YES;
        }
    }
    [self status:@"Shell: OK."];
    
    if ([filename is:[NSString stringWithFormat:@"%@/output", self.APPDIR]]) {
        [self status:@"Analyzing committed changes..."];
        if ([lastLines count] > 1) {
            if ([lastLines[[lastLines count]-1] hasPrefix:@"sudo: 3 incorrect password attempts"]) {
                [self status:@"Failed: incorrect password."];
                [self updateMarkedSource];
                return YES;
            }
        }
        if ([markedItems count] > 0) {
            NSMutableSet *affectedSystems = [NSMutableSet set];
            for (GItem *item in markedItems) {
                [affectedSystems addObject:item.system];
            }
            // refresh statuses and versions
            for (GSystem *system in affectedSystems) {
                for (GPackage *pkg in [system.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status == %@", @(GInactiveStatus)]]) {
                    [itemsController removeObject:pkg];
                }
                [system installed];
                for (GPackage *pkg in [system.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status == %@", @(GInactiveStatus)]]) {
                    NSPredicate *predicate = [itemsController filterPredicate];
                    [itemsController addObject:pkg];
                    [itemsController setFilterPredicate:predicate];
                }
            }
            [itemsTable reloadData];
            GMark mark;
            NSString *markName;
            for (GItem *item in markedItems) {
                mark = item.mark;
                markName = @[@"None", @"Install", @"Uninstall", @"Deactivate", @"Upgrade", @"Fetch", @"Clean"][mark];
                // TODO verify command did really complete
                if (mark == GInstallMark) {
                    self.marksCount--;
                    
                } else if (mark == GUninstallMark) {
                    self.marksCount--;
                    
                } else if (mark == GDeactivateMark) {
                    self.marksCount--;
                    
                } else if (mark == GUpgradeMark) {
                    self.marksCount--;
                    
                } else if (mark == GFetchMark) {
                    self.marksCount--;
                }
                [self log:[NSString stringWithFormat:@"😺 %@ %@ %@: DONE\n", markName, item.system.name, item.name]];
                item.mark = GNoMark;
                [itemsTable reloadData];
            }
            [self updateMarkedSource];
            if (!self.terminal.frontmost) {
                NSUserNotification *notification = [[NSUserNotification alloc] init];
                notification.title = @"Ready.";
                // notification.subtitle = @"%ld changes applied";
                notification.informativeText = @"The changes to the marked packages have been applied.";
                notification.soundName = NSUserNotificationDefaultSoundName;
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            }
        }
        [self status:@"Shell: OK."];
        
    } else if ([filename is:[NSString stringWithFormat:@"%@/sync", self.APPDIR]]) {
        [self performSelectorInBackground:@selector(reloadAllPackages) withObject:nil];
    }
    
    return YES;
}


-(void)reloadAllPackages {
    @autoreleasepool {
        self.ready = NO;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [itemsController setFilterPredicate:nil];
            [itemsController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[itemsController arrangedObjects] count])]];
            [itemsController setSortDescriptors:nil];
            [tableProgressIndicator startAnimation:self];
        });
        NSMutableDictionary *newIndex = [NSMutableDictionary dictionary];
        NSInteger updated = 0, new = 0;
        GPackage *previousPackage;
        GPackage *package;
        for (GSystem *system in systems) {
            NSString *systemName = system.name;
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self status:[@"Indexing " stringByAppendingFormat:@"%@...", systemName]];
            });
            [system list];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [itemsController addObjects:system.items];
                [itemsTable display];
            });
            if ([packagesIndex count] > 0 &&
                !([systemName is:@"Mac OS X"] || [systemName is:@"FreeBSD"] || [systemName is:@"iTunes"])) {
                for (package in system.items) {
                    if (package.status == GInactiveStatus)
                        continue;
                    previousPackage = (GPackage *)packagesIndex[[package key]];
                    // TODO: keep mark
                    if (previousPackage == nil) {
                        package.status = GNewStatus;
                        new += 1;
                    } else if ( ![previousPackage.version is:package.version]) {
                        package.status = GUpdatedStatus;
                        updated += 1;
                    }
                }
            }
            [newIndex addEntriesFromDictionary:system.index];
        }
        
        if ([packagesIndex count] > 0) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [sourcesOutline setDelegate:nil];
                NSString *name;
                NSArray *currentUpdated = [[[sourcesController content][2] categories] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name BEGINSWITH 'updated'"]];
                if ([currentUpdated count] > 0 && updated == 0) {
                    [[[sourcesController content][2] mutableArrayValueForKey:@"categories"] removeObject:currentUpdated[0]];
                }
                if (updated > 0) {
                    name = [NSString stringWithFormat:@"updated (%ld)", updated];
                    if ([currentUpdated count] == 0) {
                        GSource *updatedSource = [[GSource alloc] initWithName:name];
                        [[[sourcesController content][2] mutableArrayValueForKey:@"categories"] addObject:updatedSource];
                    } else
                        ((GSource *)currentUpdated[0]).name = name;
                }
                NSArray *currentNew = [[[sourcesController content][2] categories] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name BEGINSWITH 'new'"]];
                if ([currentNew count] > 0 && new == 0) {
                    [[[sourcesController content][2] mutableArrayValueForKey:@"categories"] removeObject:currentNew[0]];
                }
                if (new > 0) {
                    name = [NSString stringWithFormat:@"new (%ld)", new];
                    if ([currentNew count] == 0) {
                        GSource *newSource = [[GSource alloc] initWithName:name];
                        [[[sourcesController content][2] mutableArrayValueForKey:@"categories"] addObject:newSource];
                    } else
                        ((GSource *)currentNew[0]).name = name;
                }
                [sourcesOutline setDelegate:self];
                [packagesIndex removeAllObjects];
                [allPackages removeAllObjects];
            });
            
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [sourcesOutline setDelegate:nil];
                [self status:@"Indexing categories..."];
                for (GSystem *system in [[sourcesController content][0] categories]) {
                    system.categories = [NSMutableArray array];
                    NSMutableArray *cats = [system mutableArrayValueForKey:@"categories"];
                    for (NSString *category in [system categoriesList]) {
                        [cats addObject:[[GSource alloc] initWithName:category]];
                    }
                }
                [sourcesOutline setDelegate:self];
                [sourcesOutline reloadData];
                [sourcesOutline display];
            });
        }
        // avoid adding duplicates of inactive packages already added by system.list
        for (GSystem *system in systems) {
            [allPackages addObjectsFromArray:[system.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status != %@", @(GInactiveStatus)]]];
        }
        [packagesIndex setDictionary:newIndex];
        [markedItems removeAllObjects];
        self.marksCount = 0;
        // TODO: remember marked items
        //        marksCount = [markedItems count];
        //        if (marksCount > 0)
        //            [applyButton setEnabled:YES];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [itemsController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO]]];
            [self updateMarkedSource];
            [tableProgressIndicator stopAnimation:self];
            [applyButton setEnabled:NO];
            self.ready = YES;
            [self status:@"OK."];
        });
    }
}


- (IBAction)syncAction:(id)sender {
    [tableProgressIndicator startAnimation:self];
    [self info:@"[Contents not yet available]"];
    [self updateCmdLine:@""];
    [stopButton setEnabled:YES];
    [self sync:sender];
}


- (void)sync:(id)sender {
    self.ready = NO;
    [self status:@"Syncing..."];
    NSMutableArray *systemsToUpdateAsync = [NSMutableArray array];
    NSMutableArray *systemsToUpdate = [NSMutableArray array];
    NSMutableArray *systemsToList = [NSMutableArray array];
    for (GSystem *system in systems) {
        if ([system.name is:@"Homebrew Casks"])
            continue;
        NSString *updateCmd = [system updateCmd];
        if (updateCmd == nil)
            [systemsToList addObject:system];
        else if ([updateCmd hasPrefix:@"sudo"]) {
            [systemsToUpdateAsync addObject:system];
        } else
            [systemsToUpdate addObject:system];
    }
    if ([systemsToUpdateAsync count] > 0) {
        NSMutableArray *updateCommands = [NSMutableArray array];
        for (GSystem *system in systemsToUpdateAsync) {
            [updateCommands addObject:[system updateCmd]];
        }
        [self execute:[updateCommands join:@" ; "] withBaton:@"sync"];
    }
    if ([systemsToUpdate count] + [systemsToList count] > 0) {
        [segmentedControl setSelectedSegment:-1];
        [self updateTabView:nil];
        dispatch_queue_t queue = dispatch_queue_create("name.Guigna", DISPATCH_QUEUE_CONCURRENT);
        for (GSystem *system in systemsToList) {
            [self status:[@"Syncing " stringByAppendingFormat:@"%@...", system.name]];
            dispatch_async(queue, ^{
                [system list];
            });
        }
        for (GSystem *system in systemsToUpdate) {
            [self status:[@"Syncing " stringByAppendingFormat:@"%@...", system.name]];
            [self log:[NSString stringWithFormat: @"😺===> %@\n", [system updateCmd]]];
            dispatch_async(queue, ^{
                NSString *output = [agent outputForCommand:[system updateCmd]];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self log:output];
                });
            });
        }
        dispatch_barrier_async(queue, ^{
            if ([systemsToUpdateAsync count] == 0) {
                [self performSelectorInBackground:@selector(reloadAllPackages) withObject:nil];
            }
        });
    }
}


- (void)outlineViewSelectionDidChange:(NSOutlineView *)outline {
    [self sourcesSelectionDidChange:outline];
}

- (void)sourcesSelectionDidChange:(id)sender {
    NSMutableArray *selectedSources = [NSMutableArray arrayWithArray:[self.sourcesController selectedObjects]];
    [tableProgressIndicator startAnimation:self];
    NSMutableArray *selectedSystems = [NSMutableArray array];
    for (GSystem *system in systems) {
        if ([selectedSources containsObject:system]) {
            [selectedSystems addObject:system];
            [selectedSources removeObject:system];
        }
    }
    if ([selectedSystems count] == 0)
        [selectedSystems addObjectsFromArray:systems];
    if ([selectedSources count] == 0)
        [selectedSources addObject:[sourcesController content][0]]; // SYSTEMS
    NSString *src;
    NSString *filter = [searchField stringValue];
    [itemsController setFilterPredicate:nil];
    [itemsController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[itemsController arrangedObjects] count])]];
    [itemsController setSortDescriptors:nil];
    BOOL first = YES;
    for (GSource *source in selectedSources) {
        src = source.name;
        if ([source isKindOfClass:[GScrape class]]) {
            [itemsTable display];
            ((GScrape *)source).pageNumber = 1;
            [self updateScrape:(GScrape *)source];
        } else {
            if (first)
                [itemsController addObjects:allPackages];
            for (GSystem *system in selectedSystems) {
                NSArray *packages = @[];
                
                if ([src is:@"installed"]) {
                    if (first) {
                        [self status:@"Verifying installed packages..."];
                        [itemsController setFilterPredicate:[NSPredicate predicateWithFormat:@"status == %@", @(GUpToDateStatus)]];
                        [itemsTable display];
                    }
                    packages = [system installed];
                    
                } else if ([src is:@"outdated"]) {
                    if (first) {
                        [self status:@"Verifying outdated packages..."];
                        [itemsController setFilterPredicate:[NSPredicate predicateWithFormat:@"status == %@", @(GOutdatedStatus)]];
                        [itemsTable display];
                    }
                    packages = [system outdated];
                    
                } else if ([src is:@"inactive"]) {
                    if (first) {
                        [self status:@"Verifying inactive packages..."];
                        [itemsController setFilterPredicate:[NSPredicate predicateWithFormat:@"status == %@", @(GInactiveStatus)]];
                        [itemsTable display];
                    }
                    packages = [system inactive];
                    
                } else if ([src hasPrefix:@"updated"] || [src hasPrefix:@"new"]) {
                    src = [src split][0];
                    GStatus status = [src is:@"updated"] ? GUpdatedStatus : GNewStatus;
                    if (first) {
                        [self status:[NSString stringWithFormat:@"Verifying %@ packages...", src]];
                        [itemsController setFilterPredicate:[NSPredicate predicateWithFormat:@"status == %@", @(status)]];
                        [itemsTable display];
                        packages = [[itemsController arrangedObjects] mutableCopy];
                    }
                } else if ([src hasPrefix:@"marked"]) {
                    src = [src split][0];
                    if (first) {
                        [self status:@"Verifying marked packages..."];
                        [itemsController setFilterPredicate:[NSPredicate predicateWithFormat:@"mark != 0"]];
                        [itemsTable display];
                        packages = [[itemsController arrangedObjects] mutableCopy];
                    }
                    
                } else if (!([src is:@"SYSTEMS"]
                             || [src is:@"STATUS"]
                             || [src is:@""])) { // a category was selected
                    [itemsController setFilterPredicate:[NSPredicate predicateWithFormat:@"categories CONTAINS[c] %@", src]];
                    packages = [system.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"categories CONTAINS[c] %@", src]];
                    
                } else { // a system was selected
                    [itemsController setFilterPredicate:nil];
                    [itemsTable display];
                    packages = system.items;
                    if (first && [[itemsController selectedObjects] count] == 0) {
                        if ([[sourcesController selectedObjects] count] == 1 ) {
                            if ([[sourcesController selectedObjects][0] isKindOfClass:[GSystem class]])
                                [segmentedControl setSelectedSegment:2]; // shows System Log
                            [self updateTabView:nil];
                        }
                    }
                }
                
                if (first) {
                    [itemsController setFilterPredicate:nil];
                    [itemsController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[itemsController arrangedObjects] count])]];
                    first = NO;
                }
                
                [itemsController addObjects:packages];
                [itemsTable display];
                GMark mark = GNoMark;
                if ([packagesIndex count] > 0) {
                    for (GPackage *package in packages) {
                        if (package.status != GInactiveStatus)
                            mark = ((GPackage *)packagesIndex[[package key]]).mark;
                        else {
                            // TODO:
                            NSArray *inactivePackages = [allPackages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@ && installed == %@", package.name, package.installed]];
                            if ([inactivePackages count] > 0)
                                mark = ((GPackage*)inactivePackages[0]).mark;
                        }
                        if (mark != GNoMark)
                            package.mark = mark;
                    }
                    [itemsTable display];
                }
            }
        }
    }
    [searchField setStringValue:filter];
    [searchField performClick:self];
    if ([selectedSystems count] > 0)
        [itemsController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO]]];
    [tableProgressIndicator stopAnimation:self];
    if (self.ready && !([[statusField stringValue] hasPrefix:@"Executing"] || [[statusField stringValue] hasPrefix:@"Loading"]))
        [self status:@"OK."];
}


- (void)tableViewSelectionDidChange:(NSNotification *)table {
    NSArray *selectedItems = [itemsController selectedObjects];
    GItem *item = nil;
    if ([selectedItems count] > 0)
        item = selectedItems[0];
    if (item == nil)
        [self info:@"[No package selected]"];
    if ([selectedSegment is:@"Shell"] || ([selectedSegment is:@"Log"] && [[cmdline stringValue] is:[item log]])) {
        [segmentedControl setSelectedSegment:0];
        selectedSegment = @"Info";
    }
    [self updateTabView:item];
}


- (void)toggleTableColumn:(id)sender {
    NSTableColumn *column = [sender representedObject];
    [column setHidden:![column isHidden]];
}


- (IBAction)switchSegment:(NSSegmentedControl *)sender {
    self.selectedSegment = [sender labelForSegment:[sender selectedSegment]];
    NSArray *selectedItems = [itemsController selectedObjects];
    GItem *item = nil;
    if ([selectedItems count] > 0)
        item = selectedItems[0];
    if ([selectedSegment is:@"Shell"]
        || [selectedSegment is:@"Info"]
        || [selectedSegment is:@"Home"]
        || [selectedSegment is:@"Log"]
        || [selectedSegment is:@"Contents"]
        || [selectedSegment is:@"Spec"]
        || [selectedSegment is:@"Deps"]) {
        [self updateTabView:item];
    }
}


- (IBAction)toggleShell:(NSButton *)button {
    NSArray *selectedItems = [itemsController selectedObjects];
    GItem *item = nil;
    if ([selectedItems count] > 0)
        item = selectedItems[0];
    if ([button state] == NSOnState) {
        previousSegment = [segmentedControl selectedSegment];
        [segmentedControl setSelectedSegment:-1];
        self.selectedSegment = @"Shell";
        [self updateTabView:item];
    } else {
        if (previousSegment != -1) {
            [segmentedControl setSelectedSegment:previousSegment];
            [self updateTabView:item];
        }
    }
}


- (void)updateTabView:(GItem *)item {
    if ([segmentedControl selectedSegment] == -1) {
        [shellDisclosure setState:NSOnState];
        selectedSegment = @"Shell";
    } else {
        [shellDisclosure setState:NSOffState];
        selectedSegment = [segmentedControl labelForSegment:[segmentedControl selectedSegment]];
    }
    [clearButton setHidden: ![selectedSegment is:@"Shell"]];
    [screenshotsButton setHidden: ![item.source isKindOfClass:[GScrape class]] || ![selectedSegment is:@"Home"]];
    [moreButton setHidden: ![item.source isKindOfClass:[GScrape class]]];
    
    if ([selectedSegment is:@"Home"] || [selectedSegment is:@"Log"]) {
        [tabView selectTabViewItemWithIdentifier:@"web"];
        [webView display];
        NSString *page = nil;
        if (item != nil) {
            if ([selectedSegment is:@"Log"]) {
                if ([item.source.name is:@"MacPorts"] && item.categories == nil)
                    item = ((GPackage *)packagesIndex[[(GPackage*)item key]]);
                page = [item log];
            } else {
                if (item.homepage == nil)
                    item.homepage = [item home];
                page = item.homepage;
            }
        } else { // item is nil
            page = [cmdline stringValue];
            if ([page hasPrefix:@"Loading"])
                page = [page substringWithRange:NSMakeRange(8, [page length] - 11)];
            if (![page contains:@"http"] && ![page contains:@"www"])
                page = @"http://github.com/gui-dos/Guigna/";
            if ([[sourcesController selectedObjects] count] == 1 ) {
                if ([[sourcesController selectedObjects][0] isKindOfClass:[GSystem class]]) {
                    page = [(GSystem *)[sourcesController selectedObjects][0] log:nil];
                }
            }
        }
        if (item != nil && item.screenshots != nil && screenshotsButton.state == NSOnState) {
            NSMutableString *htmlString = [NSMutableString stringWithString:@"<html><body>"];
            for (NSString *url in [item.screenshots split]) {
                [htmlString appendFormat:@"<img src=\"%@\" border=\"1\">", url];
            }
            [htmlString appendString:@"</body></html>"];
            [[webView mainFrame] loadHTMLString:htmlString baseURL:nil];
        } else if (![page is:[webView mainFrameURL]])
            [webView setMainFrameURL:page];
        
    } else {
        if (item != nil) {
            NSString *cmd;
            cmd = [item.source.cmd lastPathComponent];
            if ([item.source.name is:@"Mac OS X"]) {
                [self updateCmdLine:[cmd stringByAppendingFormat:@" %@", item.ID]];
            }
            else
                [self updateCmdLine:[cmd stringByAppendingFormat:@" %@", item.name]];
        }
        if ([selectedSegment is:@"Info"]
            || [selectedSegment is:@"Contents"]
            || [selectedSegment is:@"Spec"]
            || [selectedSegment is:@"Deps"]) {
            [infoText setDelegate:nil]; // avoid textViewDidChangeSelection notification
            [tabView selectTabViewItemWithIdentifier:@"info"];
            [tabView display];
            if (item != nil) {
                [self info:@""];
                if (![[statusField stringValue] hasPrefix:@"Executing"])
                    [self status:@"Getting info..."];
                
                if ([selectedSegment is:@"Info"]) {
                    [self info:[item info]];
                    [infoText checkTextInDocument:nil];
                    
                } else if ([selectedSegment is:@"Contents"]) {
                    NSString *contents =[item contents];
                    if ([contents is:@""] || [contents hasSuffix:@"not installed.\n"])
                        [self info:@"[Contents not available]"];
                    else
                        [self info:[NSString stringWithFormat:@"[Click on a path to open in Finder]\n%@\nUninstall command:\n%@", contents, [(GPackage *)item uninstallCmd]]];
                    
                } else if ([selectedSegment is:@"Spec"]) {
                    [self info:[item cat]];
                    [infoText checkTextInDocument:nil];
                    
                } else if ([selectedSegment is:@"Deps"]) {
                    [tableProgressIndicator startAnimation:self];
                    [self status:@"Computing dependencies..."];
                    NSString *deps = [item deps];
                    NSString *dependents = [item dependents];
                    if ([deps is:@""] && [dependents is:@""]) {
                        [self info:@"[No dependencies]"];
                    } else {
                        deps = [NSString stringWithFormat:@"[Click on a dependency to search for it]\n%@", deps];
                        if (![dependents is:@""])
                            [self info:[NSString stringWithFormat:@"%@\nDependents:\n%@", deps, dependents]];
                        else
                            [self info:deps];
                    }
                    [tableProgressIndicator stopAnimation:self];
                }
            }
            [infoText setDelegate:self];
            if (![[statusField stringValue] hasPrefix:@"Executing"])
                [self status:@"OK."];
            
        } else if ([selectedSegment is:@"Shell"]) {
            [tabView selectTabViewItemWithIdentifier:@"log"];
            [tabView display];
        }
    }
}


- (IBAction)clear:(id)sender {
    [logText setString:@""];
}

- (void)updateCmdLine:(NSString *)cmd {
    [cmdline setStringValue:cmd];
    [cmdline display];
}


- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
    [self updateCmdLine:[@"Loading " stringByAppendingFormat:@"%@...", [webView mainFrameURL]]];
    if (self.ready && ![[statusField stringValue] hasPrefix:@"Executing"])
        [self status:[@"Loading " stringByAppendingFormat:@"%@...", [webView mainFrameURL]]];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    NSString *cmdlineString = [cmdline stringValue];
    if ([cmdlineString hasPrefix:@"Loading"]) {
        [self updateCmdLine:[cmdlineString substringWithRange:NSMakeRange(8, [cmdlineString length]-11)]];
        if (self.ready && ![[statusField stringValue] hasPrefix:@"Executing"])
            [self status:@"OK."];
    } else
        [self updateCmdLine:[webView mainFrameURL]];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    NSString *cmdlineString = [cmdline stringValue];
    if ([cmdlineString hasPrefix:@"Loading"]) {
        [self updateCmdLine:[NSString stringWithFormat:@"Failed: %@", [cmdlineString substringWithRange:NSMakeRange(8, [cmdlineString length]-11)]]];
        if (self.ready && ![[statusField stringValue] hasPrefix:@"Executing"])
            [self status:@"OK."];
    } else
        [self updateCmdLine:[webView mainFrameURL]];
}


- (void)updateScrape:(GScrape *)scrape {
    [segmentedControl setSelectedSegment:1];
    selectedSegment = @"Home";
    [tabView display];
    [self status:[@"Scraping " stringByAppendingFormat:@"%@...", scrape.name]];
    NSInteger scrapesCount = [defaults[@"ScrapesCount"] integerValue];
    NSInteger pagesToScrape = ceil(scrapesCount / 1.0 / scrape.itemsPerPage);
    for (int i = 1; i <= pagesToScrape; i++) {
        [scrape refresh];
        [itemsController addObjects:scrape.items];
        [itemsTable display];
        if (i != pagesToScrape)
            scrape.pageNumber++;
    }
    if ([itemsController selectionIndex] == NSNotFound)
        [itemsController setSelectionIndex:0];
    [_window makeFirstResponder:itemsTable];
    [itemsTable display];
    [screenshotsButton setHidden:NO];
    [moreButton setHidden:NO];
    [self updateTabView:[itemsController selectedObjects][0]];
    [tableProgressIndicator stopAnimation:self];
    if (![[statusField stringValue] hasPrefix:@"Executing"])
        [self status:@"OK."];
}

- (IBAction)moreScrapes:(id)sender {
    [tableProgressIndicator startAnimation:self];
    GScrape *scrape = [sourcesController selectedObjects][0]; // TODO: multiple scrapes
    scrape.pageNumber +=1;
    [self updateScrape:scrape];
    [itemsController rearrangeObjects];
    [tableProgressIndicator stopAnimation:self];
}

- (IBAction)toggleScreenshots:(id)sender {
    NSArray *selectedItems = [itemsController selectedObjects];
    GItem *item = nil;
    if ([selectedItems count] > 0) {
        [tableProgressIndicator startAnimation:self];
        item = selectedItems[0];
        [self updateTabView:item];
        [tableProgressIndicator stopAnimation:self];
    }
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification {
    ;
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    NSRange selectedRange = [infoText selectedRange];
    NSTextStorage *storage = [infoText textStorage];
    NSString *line = [[storage string] substringWithRange:[[storage string] paragraphRangeForRange: selectedRange]];
    
    if ([selectedSegment is:@"Contents"]) {
        NSString *file = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        // TODO detect types
        if ([file contains:@" -> "]) // Homebrew Casks
            file = [[file split:@" -> "][1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'"]];
        file = [[file split:@" ("][0] stringByExpandingTildeInPath];
        if ([file hasSuffix:@".nib"]) {
            [self execute:[NSString stringWithFormat:@"/usr/bin/plutil -convert xml1 -o - %@", file]];
            
        } else {
            [[NSWorkspace sharedWorkspace] openFile:file];
        }
        
    } else if ([selectedSegment is:@"Deps"]) {
        NSString *dep = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *selectedItems = [itemsController selectedObjects];
        GItem *item = nil;
        GPackage *pkg;
        if ([selectedItems count] > 0) {
            item = selectedItems[0];
            pkg = item.system[dep];
            if (pkg != nil) {
                [searchField setStringValue:dep];
                [searchField performClick:self];
                [itemsController setSelectedObjects:@[pkg]];
                [itemsTable scrollRowToVisible:[itemsController selectionIndex]];
                [_window makeFirstResponder: itemsTable];
            }
        }
    }
}


- (IBAction)executeCmdLine:(id)sender {
    NSArray *selectedItems = [itemsController selectedObjects];
    GItem *item = nil;
    NSString *input, *output;
    if ([selectedItems count] > 0)
        item = selectedItems[0];
    input = cmdline.stringValue;
    if (input == nil)
        return;
    NSMutableArray *tokens = [[input split] mutableCopy];
    NSString *cmd = tokens[0];
    if ([cmd hasPrefix:@"http"] || [cmd hasPrefix:@"www"]) { // TODO
        if ([cmd hasPrefix:@"www"])
            [self updateCmdLine:[NSString stringWithFormat:@"http://%@",cmd]];
        [segmentedControl setSelectedSegment:1];
        selectedSegment = @"Home";
        [self updateTabView:nil];
    } else {
        [segmentedControl setSelectedSegment:-1];
        [self updateTabView:item];
        if ([cmd is:@"sudo"])
            [self sudo:[input substringFromIndex:5]];
        else {
            for (GSystem *system in systems) {
                if ([system.cmd hasSuffix:cmd]) {
                    cmd = system.cmd;
                    tokens[0] = cmd;
                    break;
                }
            }
            if ( ![cmd hasPrefix:@"/"]) {
                NSString *output = [agent outputForCommand:[NSString stringWithFormat:@"/bin/bash -l -c which__%@", cmd]];
                if ([output length] != 0)
                    tokens[0] = [output substringToIndex:[output length]-1];
                // else // TODO: show stderr
            }
            cmd = [tokens join];
            [self log:[NSString stringWithFormat:@"😺===> %@\n", cmd]];
            [self status:[NSString stringWithFormat:@"Executing '%@'...", cmd]];
            cmd = [NSString stringWithFormat:@"/bin/bash -l -c %@", [cmd stringByReplacingOccurrencesOfString:@" " withString:@"__"]];
            output = [agent outputForCommand:cmd];
            [self status:@"OK."];
            [self log:output];
        }
    }
}


- (IBAction)executeCommandsMenu:(id)sender {
    NSArray *selectedItems = [itemsController selectedObjects];
    GItem *item = nil;
    if ([selectedItems count] > 0)
        item = selectedItems[0];
    NSString *title = [sender titleOfSelectedItem];
    GSystem *system = item.system;
    NSString *command;
    if (system != nil) {
        for (NSArray *commandArray in [system availableCommands]) {
            if ([commandArray[0] is:title]) {
                command = commandArray[1];
                break;
            }
        }
        command = [command stringByReplacingOccurrencesOfString:@"CMD" withString:[system.cmd lastPathComponent]];
        [self updateCmdLine:command];
        [self executeCmdLine:sender];
    }
}


- (void)execute:(NSString *)cmd withBaton:(NSString *)baton {
    NSString *briefCmd = [[[cmd split:@" ; "] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF BEGINSWITH 'sudo mv'"]] join:@" ; "];
    [self status:[NSString stringWithFormat:@"Executing '%@' in the shell...", briefCmd]];
    [self log:[NSString stringWithFormat:@"😺===> %@\n", briefCmd]];
    NSString *command;
    if ([baton is:@"relaunch"]) {
        self.ready = NO;
        command = [NSString stringWithFormat:@"%@ ; osascript -e 'tell app \"Guigna\"' -e 'quit' -e 'end tell' &>/dev/null ; osascript -e 'tell app \"Guigna\"' -e 'ignoring application responses' -e 'activate' -e 'end ignoring' -e 'end tell' &>/dev/null", cmd];
    }
    else
        command = [NSString stringWithFormat:@"%@ ; guigna --baton %@", cmd, baton];
    if (_adminPassword != nil) {
        command = [command stringByReplacingOccurrencesOfString:@"sudo" withString:[NSString stringWithFormat:@"echo \"%@\" | sudo -S", _adminPassword]];
    }
    [self raiseShell:self];
    [terminal doScript:command in:self.shell];
}

- (void)execute:(NSString *)cmd {
    [self execute:cmd withBaton:@"output"];
}

- (void)sudo:(NSString *)cmd withBaton:(NSString *)baton {
    NSString *command = [NSString stringWithFormat:@"sudo %@", cmd];
    [self execute:command withBaton:baton];
}

- (void)sudo:(NSString *)cmd {
    [self sudo:cmd withBaton:@"output"];
}

- (void)executeAsRoot:(NSString *)cmd {
    system([[NSString stringWithFormat: @"osascript -e 'do shell script \"%@\" with administrator privileges'", cmd] UTF8String]);
}

- (void)minuteCheck:(NSTimer *)timer {
    if ([self.shellWindow.name contains:@"sudo"]) {
        if ([NSApp isActive])
            [self raiseShell:self];
        [NSApp requestUserAttention:NSCriticalRequest];
    }
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSString *title = [menu title];
    if ([title is:@"ItemsColumnsMenu"]) {
        for (NSMenuItem *menuItem in menu.itemArray) {
            NSTableColumn *column = [menuItem representedObject];
            [menuItem setState:column.isHidden ? NSOffState : NSOnState];
        }
        
    } else {
        NSMutableArray *selectedItems = [[itemsController selectedObjects] mutableCopy];
        if ([itemsTable clickedRow] != -1)
            [selectedItems addObject:[itemsController arrangedObjects][[itemsTable clickedRow]]];
        
        if ([title is:@"Mark"]) { // TODO: Disable marks based on status
            [tableProgressIndicator startAnimation:self];
            [self status:@"Analyzing selected items..."];
            NSMenuItem *installMenu = [menu itemWithTitle:@"Install"];
            NSMutableArray *markedOptions;
            for (GItem *item in selectedItems) {
                if (item.system == nil)
                    continue;
                NSArray *availableOptions = [[item.system options:(GPackage *)item] split];
                markedOptions = [[((GPackage *)item).markedOptions split] mutableCopy];
                NSArray *currentOptions = [((GPackage *)item).options split];
                if ([markedOptions count] == 0 && [currentOptions count] > 0) {
                    [markedOptions addObjectsFromArray:currentOptions];
                    ((GPackage*)item).markedOptions = [markedOptions join];
                }
                if ([availableOptions count] > 0 && ![availableOptions[0] is:@""]) {
                    NSMenu *optionsMenu =[[NSMenu alloc] initWithTitle:@"Options"];
                    for (NSString *availableOption in availableOptions)  {
                        [optionsMenu addItemWithTitle:availableOption action:@selector(mark:) keyEquivalent:@""];
                        NSMutableSet *options = [NSMutableSet setWithArray:markedOptions];
                        [options unionSet:[NSSet setWithArray:currentOptions]];
                        for (NSString *option in options) {
                            if ([option is:availableOption]) {
                                [[optionsMenu itemWithTitle:availableOption] setState:NSOnState];
                            }
                        }
                    }
                    [installMenu setSubmenu:optionsMenu];
                } else {
                    if ([installMenu hasSubmenu]) {
                        [[installMenu submenu] removeAllItems];
                        [installMenu setSubmenu:nil];
                    }
                }
            }
            [tableProgressIndicator stopAnimation:self];
            [self status:@"OK."];
            
        } else if ([title is:@"Commands"]) {
            while ([commandsPopUp numberOfItems] > 1) {
                [commandsPopUp removeItemAtIndex:1];
            }
            if ([selectedItems count] == 0) {
                [commandsPopUp addItemWithTitle:@"[no package selected]"];
            } else {
                GItem *item = selectedItems[0]; // TODO
                if (item.system != nil) {
                    for (NSArray *commandArray in [item.system availableCommands]) {
                        [commandsPopUp addItemWithTitle:commandArray[0]];
                    }
                }
            }
        }
    }
}


- (IBAction)marks:(id)sender {
    // TODO
    [self showMarkMenu:self];
}


- (IBAction)showMarkMenu:(id)sender {
    [NSMenu popUpContextMenu:markMenu withEvent:[NSApp currentEvent] forView:itemsTable];
}


- (IBAction)mark:(id)sender {
    NSMutableArray *selectedItems = [[itemsController selectedObjects] mutableCopy];
    if ([itemsTable clickedRow] != -1)
        [selectedItems addObject:[itemsController arrangedObjects][[itemsTable clickedRow]]];
    NSString *title;
    GMark mark = GNoMark;
    for (GItem *item in selectedItems) {
        title = [sender title];
        
        if ([title is:@"Install"]) {
            if (item.URL != nil && [item.source isKindOfClass:[GScrape class]]) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:item.URL]];
                continue;
            }
            mark = GInstallMark;
        }
        else if ([title is:@"Uninstall"])
            mark = GUninstallMark;
        else if ([title is:@"Deactivate"])
            mark = GDeactivateMark;
        else if ([title is:@"Upgrade"])
            mark = GUpgradeMark;
        else if ([title is:@"Fetch"]) {
            if (item.URL != nil && [item.source isKindOfClass:[GScrape class]]) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:item.URL]];
                continue;
            }
            mark = GFetchMark;
        }
        else if ([title is:@"Clean"]) // TODO: clean immediately
            mark = GCleanMark;
        else if ([title is:@"Unmark"]) {
            mark = GNoMark;
            if ([item isKindOfClass:[GPackage class]]) {
                ((GPackage *)item).markedOptions = nil;
                ((GPackage *)packagesIndex[[(GPackage *)item key]]).markedOptions = nil;
            }
        } else { // variant/option submenu selected
            NSMutableArray *markedOptions = [NSMutableArray array];
            if (((GPackage *)item).markedOptions != nil)
                markedOptions = [[((GPackage *)item).markedOptions split] mutableCopy];
            if ([sender state] == NSOffState) {
                [markedOptions addObject:title];
            } else {
                [markedOptions removeObject:title];
            }
            NSString *options = nil;
            if ([markedOptions count] > 0) {
                options = [markedOptions join];
            }
            ((GPackage *)item).markedOptions = options;
            ((GPackage *)packagesIndex[[(GPackage *)item key]]).markedOptions = options;
            mark = GInstallMark;
        }
        if ([title is:@"Unmark"]) {
            if (item.mark != GNoMark)
                marksCount--;
        } else {
            if (item.mark == GNoMark)
                marksCount++;
        }
        item.mark = mark;
        GPackage *package;
        if (item.status == GInactiveStatus) {
            package = [allPackages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@ && installed == %@", item.name, item.installed]][0];
        } else {
            package = (GPackage *)packagesIndex[[(GPackage *)item key]];
            package.version = ((GPackage *)item).version;
            package.options = ((GPackage *)item).options;
        }
        package.mark = mark;
    }
    [self updateMarkedSource];
}

- (void)updateMarkedSource {
    [sourcesOutline setDelegate:nil];
    NSArray *currentMarked = [[[sourcesController content][2] categories] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name BEGINSWITH 'marked'"]];
    if ([currentMarked count] > 0 && marksCount == 0) {
        [[[sourcesController content][2] mutableArrayValueForKey:@"categories"] removeObject:currentMarked[0]];
    }
    if (marksCount > 0) {
        NSString *name = [NSString stringWithFormat:@"marked (%ld)", marksCount];
        if ([currentMarked count] == 0) {
            GSource *markedSource = [[GSource alloc] initWithName:name];
            [[[sourcesController content][2] mutableArrayValueForKey:@"categories"] addObject:markedSource];
        } else
            ((GSource *)currentMarked[0]).name = name;
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%ld", self.marksCount]];
    } else
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:nil];
    [sourcesOutline setDelegate:self];
    [applyButton setEnabled:(self.marksCount > 0)];
}

- (IBAction)apply:(id)sender {
    self.ready = NO;
    self.markedItems = [[allPackages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"mark != 0"]] mutableCopy];
    self.marksCount = [markedItems count];
    if (marksCount == 0)
        return;
    [applyButton setEnabled:NO];
    [stopButton setEnabled:YES];
    [itemsController setSelectedObjects:nil];
    [segmentedControl setSelectedSegment:-1];
    selectedSegment = @"Shell";
    [self updateTabView:nil];
    NSMutableArray *tasks = [NSMutableArray array];
    NSMutableSet *markedSystems = [NSMutableSet set];
    for (GPackage *item in markedItems) {
        [markedSystems addObject:item.system];
    }
    NSMutableDictionary *systemsDict = [NSMutableDictionary dictionary];
    for (GSystem *system in markedSystems) {
        systemsDict[system.name] = [NSMutableArray array];
    }
    for (GPackage *item in markedItems) {
        [systemsDict[item.system.name] addObject:item];
    }
    NSArray *prefixes = @[@"/opt/local", @"/usr/local", @"/sw", @"/usr/pkg"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *detectedPrefixes = [NSMutableArray array];
    for (NSString *prefix in prefixes) {
        if ([fileManager fileExistsAtPath:prefix])
            [detectedPrefixes addObject:prefix];
    }
    for (GSystem *system in systems) {
        if ([detectedPrefixes containsObject:system.prefix])
            [detectedPrefixes removeObject:system.prefix];
    }
    GMark mark;
    NSString *markName;
    for (GSystem *system in markedSystems) {
        NSMutableArray *systemTasks = [NSMutableArray array];
        NSMutableArray *systemCommands = [NSMutableArray array];
        NSString *command;
        BOOL hidesOthers = NO;
        for (GPackage *item in [systemsDict[system.name] allObjects]) {
            mark = item.mark;
            markName = @[@"None", @"Install", @"Uninstall", @"Deactivate", @"Upgrade", @"Fetch", @"Clean"][mark];
            command = nil;
            hidesOthers = NO;
            
            if (mark == GInstallMark) {
                command = [item installCmd];
                
                if (!([item.system.name is:@"Homebrew Casks"] || [item.system.name is:@"Rudix"]))
                    hidesOthers = YES;
                
            } else if (mark == GUninstallMark) {
                command = [item uninstallCmd];
                
            } else if (mark == GDeactivateMark) {
                command = [item deactivateCmd];
                
            } else if (mark == GUpgradeMark) {
                command = [item upgradeCmd];
                hidesOthers = YES;
                
            } else if (mark == GFetchMark) {
                command = [item fetchCmd];
                
            } else if (mark == GCleanMark) {
                command = [item cleanCmd];
            }
            if (command != nil) {
                if ([defaults[@"DebugMode"] isEqual:@YES])
                    command = [item.system verbosifiedCmd:command];
                [systemCommands addObject:command];
            }
        }
        if (hidesOthers && ([systems count] > 1 || [detectedPrefixes count] > 0)) {
            for (GSystem *otherSystem in systems) {
                if ([otherSystem isEqual:system])
                    continue;
                if ([otherSystem hideCmd] != nil &&
                    ![[otherSystem hideCmd] is:[system hideCmd]] &&
                    ![systemTasks containsObject:otherSystem.hideCmd] &&
                    [fileManager fileExistsAtPath:otherSystem.prefix])
                {
                    [tasks addObject:[otherSystem hideCmd]];
                    [systemTasks addObject:[otherSystem hideCmd]];
                    // TODO: set GOnlineMode
                }
            }
            for (NSString *prefix in detectedPrefixes) {
                [tasks addObject:[NSString stringWithFormat:@"sudo mv %@ %@_off", prefix, prefix]];
            }
        }
        [tasks addObjectsFromArray:systemCommands];
        if (hidesOthers && ([systems count] > 1 || [detectedPrefixes count] > 0)) {
            for (GSystem *otherSystem in systems) {
                if ([otherSystem isEqual:system])
                    continue;
                if ([otherSystem hideCmd] != nil &&
                    ![[otherSystem hideCmd] is:[system hideCmd]] &&
                    ![systemTasks containsObject:otherSystem.unhideCmd] &&
                    [fileManager fileExistsAtPath:otherSystem.prefix])
                {
                    [tasks addObject:[otherSystem unhideCmd]];
                    [systemTasks addObject:[otherSystem unhideCmd]];
                }
            }
            for (NSString *prefix in detectedPrefixes) {
                [tasks addObject:[NSString stringWithFormat:@"sudo mv %@_off %@", prefix, prefix]];
            }
        }
    }
    [self execute:[tasks join:@" ; "]];
}

- (IBAction)stop:(id)sender {
    // TODO: get terminal PID
    if (self.agent.processID != -1)
        NSLog(@"Agent PID: %i", self.agent.processID);
    for (NSString *process in shell.processes) {
        NSLog(@"Terminal Process: %@", process);
    }
}


- (IBAction)details:(id)sender {
}


- (IBAction)raiseBrowser:(id)sender {
    NSArray *selectedItems = [itemsController selectedObjects];
    GItem *item = nil;
    if ([selectedItems count] > 0)
        item = selectedItems[0];
    NSString *url = [cmdline stringValue];
    if (item == nil && ![url hasPrefix:@"http"])
        url = @"http://github.com/gui-dos/Guigna/";
    if ([url hasPrefix:@"Loading"]) {
        url = [url substringWithRange:NSMakeRange(8, [url length] - 11)];
        [self updateCmdLine:url];
        if (![[statusField stringValue] hasPrefix:@"Executing"])
            [self status:[NSString stringWithFormat:@"Launched in browser: %@", url]];
    }
    else if (![url hasPrefix:@"http"]) {
        if (item.homepage != nil)
            url = item.homepage;
        else
            url = [item home];
    }
    [browser activate];
    if ([[browser windows] count] == 0) {
        [[browser windows] addObject:[[[browser classForScriptingClass:@"document"] alloc] init]];
        
    } else {
        [[[browser windows][0] tabs] addObject:[[[browser classForScriptingClass:@"tab"] alloc] init]];
        ((SafariWindow *)([browser windows][0])).currentTab = [[browser windows][0] tabs][[[[browser windows][0] tabs] count]-1];
    }
    [[[browser windows][0] document] setURL:[NSURL URLWithString:url]];
}


- (IBAction)raiseShell:(id)sender {
    for (TerminalWindow *window in terminal.windows) {
        if (![window.name contains:@"Guigna "])
            window.visible = NO;
    }
    [self.terminal activate];
    NSRect frame = tabView.frame;
    frame.size.width += 0;
    frame.size.height -= 3;
    frame.origin.x = _window.frame.origin.x + sourcesOutline.superview.frame.size.width + 1;
    frame.origin.y = _window.frame.origin.y + 22;
    for (TerminalWindow *window in terminal.windows) {
        if ([window.name contains:@"Guigna "])
            self.shellWindow = window;
    }
    shellWindow.frame = frame;
    for (TerminalWindow *window in terminal.windows) {
        if (![window.name contains:@"Guigna "])
            window.frontmost = NO;
    }
}


- (IBAction)open:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [_window makeKeyAndOrderFront:nil];
    [self raiseShell:self];
}


- (IBAction)options:(id)sender {
    [NSApp beginSheet:optionsPanel modalForWindow:_window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [optionsPanel orderOut:self];
}

- (IBAction)closeOptions:(id)sender {
    [NSApp endSheet:optionsPanel];
}


- (void)optionsStatus:(NSString *)msg {
    if ([msg hasSuffix:@"..."]) {
        [optionsProgressIndicator startAnimation:self];
        if ([optionsStatusField.stringValue hasPrefix:@"Executing"])
            msg = [NSString stringWithFormat:@"%@ %@", optionsStatusField.stringValue, msg];
    }
    else
        [optionsProgressIndicator stopAnimation:self];
    [self status:msg];
    if ([msg is:@"OK."])
        msg = @"";
    [optionsStatusField setStringValue:msg];
    [optionsStatusField display];
}


- (IBAction)preferences:(id)sender { // TODO
    self.ready = NO;
    [optionsPanel display];
    if ([sender isKindOfClass:[NSSegmentedControl class]]) {
        NSString *theme = [sender labelForSegment:[(NSSegmentedControl *)sender selectedSegment]];
        [self applyTheme:theme];
        
    } else {
        NSString *title = [sender title];
        NSInteger state = [sender state];
        GSource *source = nil;
        GSystem *system = nil;
        NSString *command;
        NSInteger status = GOffState;
        if (state == NSOnState) {
            [self optionsStatus:[NSString stringWithFormat: @"Adding %@...", title]];
            
            if ([title is:@"Homebrew"]) {
                command = @"/usr/local/bin/brew";
                if ([[NSFileManager defaultManager] fileExistsAtPath:command])
                    system = [[GHomebrew alloc] initWithAgent:self.agent];
                
            } else if ([title is:@"MacPorts"]) {
                command = @"/opt/local/bin/port";
                system = [[GMacPorts alloc] initWithAgent:self.agent];
                if (![[NSFileManager defaultManager] fileExistsAtPath:command]) {
                    [self execute:@"cd ~/Library/Application\\ Support/Guigna/Macports ; /usr/bin/rsync -rtzv rsync://rsync.macports.org/release/tarballs/PortIndex_darwin_12_i386/PortIndex PortIndex"];
                    system.mode = GOnlineMode;
                }
                
            } else if ([title is:@"Fink"]) {
                command = @"/sw/bin/fink";
                system = [[GFink alloc] initWithAgent:self.agent];
                system.mode = ([[NSFileManager defaultManager] fileExistsAtPath:command]) ? GOfflineMode : GOnlineMode;
                
            } else if ([title is:@"pkgsrc"]) {
                command = @"/usr/pkg/sbin/pkg_info";
                system = [[GPkgsrc alloc] initWithAgent:self.agent];
                system.mode = ([[NSFileManager defaultManager] fileExistsAtPath:command]) ? GOfflineMode : GOnlineMode;
                
            } else if ([title is:@"FreeBSD"]) {
                system = [[GFreeBSD alloc] initWithAgent:self.agent];
                system.mode = GOnlineMode;
                
            } else if ([title is:@"Rudix"]) {
                command = @"/usr/local/bin/rudix";
                system = [[GRudix alloc] initWithAgent:self.agent];
                system.mode = ([[NSFileManager defaultManager] fileExistsAtPath:command]) ? GOfflineMode : GOnlineMode;
                
            } else if ([title is:@"iTunes"]) {
                system = [[GITunes alloc] initWithAgent:self.agent];
            }
            
            if (system != nil) {
                [systems addObject:system];
                source = system;
                NSInteger systemsCount = [[[sourcesController content][0] valueForKey:@"categories"] count];
                [[[sourcesController content][0] mutableArrayValueForKey:@"categories"] addObject:source];
                // selecting the new system avoids memory peak > 1.5 GB:
                [sourcesController setSelectionIndexPath:[[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:systemsCount]];
                [sourcesOutline reloadData];
                [sourcesOutline display];
                [self sourcesSelectionDidChange:[[sourcesController content][0] mutableArrayValueForKey:@"categories"][systemsCount]];
                [itemsController addObjects:[system list]];
                [itemsTable display];
                [allPackages addObjectsFromArray:system.items];
                [packagesIndex addEntriesFromDictionary:system.index];
                // duplicate code from reloalAllPackages
                source.categories = [NSMutableArray array];
                NSMutableArray *cats = [source mutableArrayValueForKey:@"categories"];
                for (NSString *category in [system categoriesList]) {
                    [cats addObject:[[GSource alloc] initWithName:category]];
                }
                [sourcesOutline reloadData];
                [sourcesOutline display];
                [itemsController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO]]];
                [self optionsStatus:@"OK."];
            } else {
                [self optionsStatus:[NSString stringWithFormat:@"%@'s %@ not detected.", title, command]];
            }
            
        } else {
            [self optionsStatus:[NSString stringWithFormat: @"Removing %@...", title]];
            NSArray *filtered = [[[sourcesController content][0] categories]filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", title]];
            if ([filtered count] > 0) {
                source = filtered[0];
                status = source.status;
                if (status == GOnState) {
                    [itemsController removeObjects:[items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"system.name == %@", title]]];
                    [allPackages filterUsingPredicate:[NSPredicate predicateWithFormat:@"system.name != %@", title]];
                    for (GPackage *pkg in source.items) {
                        [packagesIndex removeObjectForKey:[pkg key]];
                    }
                    [source.items removeAllObjects];
                    [[[sourcesController content][0] mutableArrayValueForKey:@"categories"] removeObject:source];
                    [systems removeObject:source];
                }
            }
            [self optionsStatus:@"OK."];
        }
    }
    self.ready = YES;
}

-(void)applyTheme:(NSString *)theme {
    if ([theme is:@"Retro"]) {
        [_window setBackgroundColor:[NSColor greenColor]];
        [[segmentedControl superview] setWantsLayer:YES];
        [segmentedControl superview].layer.backgroundColor = [NSColor blackColor].CGColor;
        [itemsTable setBackgroundColor:[NSColor blackColor]];
        [itemsTable setUsesAlternatingRowBackgroundColors:NO];
        self.tableFont = [NSFont fontWithName:@"Andale Mono" size:11.0];
        self.tableTextColor = [NSColor greenColor];
        [itemsTable setGridColor:[NSColor greenColor]];
        [itemsTable setGridStyleMask:NSTableViewDashedHorizontalGridLineMask];
        [(NSScrollView *)[[sourcesOutline superview] superview] setBorderType:NSLineBorder];
        [sourcesOutline setBackgroundColor:[NSColor blackColor]];
        [segmentedControl setSegmentStyle:NSSegmentStyleSmallSquare];
        [commandsPopUp setBezelStyle:NSSmallSquareBezelStyle];
        [(NSScrollView *)[[infoText superview] superview] setBorderType:NSLineBorder];
        [infoText setBackgroundColor:[NSColor blackColor]];
        [infoText setTextColor:[NSColor greenColor]];
        NSMutableDictionary *cyanLinkAttributes = linkTextAttributes.mutableCopy;
        cyanLinkAttributes[NSForegroundColorAttributeName] = [NSColor cyanColor];
        infoText.linkTextAttributes = cyanLinkAttributes;
        [(NSScrollView *)[[logText superview] superview] setBorderType:NSLineBorder];
        [logText setBackgroundColor:[NSColor blueColor]];
        [logText setTextColor:[NSColor whiteColor]];
        self.logTextColor = [NSColor whiteColor];
        [statusField setDrawsBackground:YES];
        [statusField setBackgroundColor:[NSColor greenColor]];
        [cmdline setBackgroundColor:[NSColor blueColor]];
        [cmdline setTextColor:[NSColor whiteColor]];
        [clearButton setBezelStyle:NSSmallSquareBezelStyle];
        [screenshotsButton setBezelStyle:NSSmallSquareBezelStyle];
        [moreButton setBezelStyle:NSSmallSquareBezelStyle];
        [statsLabel setDrawsBackground:YES];
        [statsLabel setBackgroundColor:[NSColor greenColor]];
        shell.backgroundColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0];
        shell.normalTextColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
    } else { // Default theme
        [_window setBackgroundColor:[NSColor windowBackgroundColor]];
        [segmentedControl superview].layer.backgroundColor = [NSColor windowBackgroundColor].CGColor;
        [itemsTable setBackgroundColor:[NSColor whiteColor]];
        [itemsTable setUsesAlternatingRowBackgroundColors:YES];
        self.tableFont = [NSFont controlContentFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
        self.tableTextColor = [NSColor blackColor];
        [itemsTable setGridStyleMask:NSTableViewGridNone];
        [itemsTable setGridColor:[NSColor gridColor]];
        [(NSScrollView *)[[sourcesOutline superview] superview] setBorderType:NSGrooveBorder];
        [sourcesOutline setBackgroundColor:self.sourceListBackgroundColor];
        [segmentedControl setSegmentStyle:NSSegmentStyleTexturedRounded];
        [commandsPopUp setBezelStyle:NSTexturedRoundedBezelStyle];
        [(NSScrollView *)[[infoText superview] superview] setBorderType:NSGrooveBorder];
        [infoText setBackgroundColor:[NSColor colorWithCalibratedRed:0.82290249429999995 green:0.97448979589999996 blue:0.67131519269999995 alpha:1.0]]; // light green
        [infoText setTextColor:[NSColor blackColor]];
        infoText.linkTextAttributes = linkTextAttributes;
        [(NSScrollView *)[[logText superview] superview] setBorderType:NSGrooveBorder];
        [logText setBackgroundColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.8 alpha:1.0]]; // light yellow
        [logText setTextColor:[NSColor blackColor]];
        self.logTextColor = [NSColor blackColor];
        [statusField setDrawsBackground:NO];
        [cmdline setBackgroundColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.8 alpha:1.0]];
        [cmdline setTextColor:[NSColor blackColor]];
        [clearButton setBezelStyle:NSTexturedRoundedBezelStyle];
        [screenshotsButton setBezelStyle:NSTexturedRoundedBezelStyle];
        [moreButton setBezelStyle:NSTexturedRoundedBezelStyle];
        [statsLabel setDrawsBackground:NO];
        shell.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.8 alpha:1.0];
        shell.normalTextColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    }
    defaults[@"Theme"] = theme;
}


- (IBAction)toolsAction:(id)sender {
    [NSMenu popUpContextMenu:toolsMenu withEvent:[NSApp currentEvent] forView:itemsTable];
}

- (IBAction)tools:(id)sender {
    NSString *title = [sender title];
    if ([title is:@"Install Fink"]) {
        [self execute:[GFink setupCmd] withBaton:@"relaunch"];
        // TODO: activate system
    }
    
    else if ([title is:@"Remove Fink"]) {
        [self execute:[GFink removeCmd] withBaton:@"relaunch"];
    }
    
    else if ([title is:@"Install Homebrew"]) {
        [self execute:[GHomebrew setupCmd] withBaton:@"relaunch"];
    }
    
    else if ([title is:@"Install Homebrew Cask"]) {
        [self execute:[GHomebrewCasks setupCmd] withBaton:@"relaunch"];
    }
    
    else if ([title is:@"Remove Homebrew"]) {
        [self execute:[GHomebrew removeCmd] withBaton:@"relaunch"];
    }
    
    else if ([title is:@"Install pkgsrc"]) {
        [self execute:[GPkgsrc setupCmd] withBaton:@"relaunch"];
    }
    
    else if ([title is:@"Fetch pkgsrc and INDEX"]) {
        [self execute:@"cd ~/Library/Application\\ Support/Guigna/pkgsrc ; curl -L -O ftp://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/INDEX ; curl -L -O ftp://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc.tar.gz ; sudo tar -xvzf pkgsrc.tar.gz -C /usr"];
    }
    
    else if ([title is:@"Remove pkgsrc"]) {
        [self execute:[GPkgsrc removeCmd] withBaton:@"relaunch"];
    }
    
    else if ([title is:@"Fetch FreeBSD INDEX"]) {
        [self execute:@"cd ~/Library/Application\\ Support/Guigna/FreeBSD ; curl -L -O ftp://ftp.freebsd.org/pub/FreeBSD/ports/packages/INDEX" withBaton:@"relaunch"];
    }
    
    else if ([title is:@"Install Rudix"]) {
        [self execute:[GRudix setupCmd] withBaton:@"relaunch"];
    }
    
    else if ([title is:@"Remove Rudix"]) {
        [self execute:[GRudix removeCmd] withBaton:@"relaunch"];
    }
    
    else if ([title is:@"Fetch MacPorts PortIndex"]) {
        [self execute:@"cd ~/Library/Application\\ Support/Guigna/Macports ; /usr/bin/rsync -rtzv rsync://rsync.macports.org/release/tarballs/PortIndex_darwin_12_i386/PortIndex PortIndex"];
        
    } else if ([title is:@"Install Gentoo"]) {
        [self execute:[GGentoo setupCmd] withBaton:@"relaunch"];
        
    } else if ([title is:@"Build Gtk-OSX"]) {
        [self execute:[GGtkOSX setupCmd] withBaton:@"relaunch"];
        
    } else if ([title is:@"Remove Gtk-OSX"]) {
        [self execute:[GGtkOSX removeCmd] withBaton:@"relaunch"];
    }
}


- (IBAction)search:(id)sender {
    [_window makeFirstResponder:searchField];
}


- (IBAction)showHelp:(id)sender { // TODO
    cmdline.stringValue = @"http://github.com/gui-dos/Guigna/wiki/The-Guigna-Guide";
    [segmentedControl setSelectedSegment:1];
    selectedSegment = @"Home";
    [self updateTabView:nil];
}

/**
 Returns the directory the application uses to store the Core Data store file. This code uses a directory named "Guigna" in the user's Library directory. // /Library/Application Support
 */
- (NSURL *)applicationFilesDirectory {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"Guigna"];
}


@end


@implementation GDefaultsTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    return ([value isEqual:@0] || value == nil) ? @NO : @YES;
}

- (id)reverseTransformedValue:(id)value {
    return [value isEqual:@YES] ? @1 : @0;
}

@end

