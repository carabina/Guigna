# require 'GAdditions'
# require 'GAgent'
# require 'GuignaItems'
# require 'GuignaSystems'
# require 'GuignaScrapes'
# require 'GuignaRepos'

OFF = OFFLINE = 0
ON  = ONLINE  = 1
HIDDEN = 2

class GuignaAppDelegate
  
  attr_accessor :agent, :defaults
  attr_accessor :window
  attr_accessor :sourcesOutline, :itemsTable, :searchField
  attr_accessor :tabView, :infoText, :webView, :logText
  attr_accessor :segmentedControl, :commandsPopUp, :shellDisclosure, :cmdline
  attr_accessor :statusField, :clearButton, :screenshotsButton, :moreButton, :statsLabel
  attr_accessor :progressIndicator, :tableProgressIndicator
  attr_accessor :applyButton, :stopButton, :syncButton
  attr_accessor :statusItem, :statusMenu, :toolsMenu, :markMenu
  attr_accessor :optionsPanel, :optionsProgressIndicator, :optionsStatusField, :themesSegmentedControl
  attr_accessor :terminal, :shell, :shellWindow, :browser
  attr_accessor :sourcesController, :itemsController
  attr_accessor :sources, :systems, :scrapes, :repos
  attr_accessor :items, :all_packages, :packages_index, :marked_items
  attr_accessor :marks_count, :selected_segment, :previous_segment
  attr_accessor :tableFont, :tableTextColor, :logTextColor, :linkTextAttributes, :sourceListBackgroundColor
  attr_accessor :adminPassword, :minute_timer, :ready
  
  def status(msg)
    if msg.end_with? "..."
      progressIndicator.startAnimation self
      if statusField.stringValue.start_with? "Executing"
        msg = "#{statusField.stringValue} #{msg}"
      end
    else
      progressIndicator.stopAnimation self
      self.ready = true
    end
    statusField.stringValue = msg
    statusField.toolTip = msg
    statusField.display
    if msg.end_with?("...")
      statusItem.title = "💤"
    else
      statusItem.title = "😺"
    end
    statusMenu.itemAtIndex(0).title = msg
    statusItem.toolTip = msg
  end
  
  
  def info(msg)
    infoText.string = msg
    infoText.scrollRangeToVisible [0,0]
    infoText.display
    tabView.display
  end
  
  
  def log(text)
    string = NSAttributedString.alloc.initWithString(text, attributes:{NSFontAttributeName => NSFont.fontWithName("Andale Mono", size:11.0), NSForegroundColorAttributeName => @logTextColor})
    storage = logText.textStorage
    storage.beginEditing
    storage.appendAttributedString string
    storage.endEditing
    logText.display
    logText.scrollRangeToVisible([logText.string.length, 0])
    tabView.display
  end
  
  def shell_columns
    attrs = {NSFontAttributeName => NSFont.fontWithName("Andale Mono", size:11.0)}
    char_width = ("MMM".sizeWithAttributes(attrs).width - "M".sizeWithAttributes(attrs).width) / 2
    columns = ((infoText.frame.size.width - 16) / char_width).round
  end
  
  def applicationDidFinishLaunching(notification)
    
    tableProgressIndicator.startAnimation self

    defaultsTransformer = GDefaultsTransformer.alloc.init
    NSValueTransformer.setValueTransformer(defaultsTransformer, forName:"GDefaultsTransformer")
    statusTransformer = GStatusTransformer.alloc.init
    NSValueTransformer.setValueTransformer(statusTransformer, forName:"GStatusTransformer")
    sourceTransformer = GSourceTransformer.alloc.init
    NSValueTransformer.setValueTransformer(sourceTransformer, forName:"GSourceTransformer")
    markTransformer = GMarkTransformer.alloc.init
    NSValueTransformer.setValueTransformer(markTransformer, forName:"GMarkTransformer")
    
    self.statusItem = NSStatusBar.systemStatusBar.statusItemWithLength(NSVariableStatusItemLength)
    statusItem.setTitle "😺"
    statusItem.setHighlightMode true
    statusItem.setMenu statusMenu
    status_column = itemsTable.tableColumnWithIdentifier 'status'
    status_column.setSortDescriptorPrototype NSSortDescriptor.sortDescriptorWithKey('status_order', ascending:false, selector:'compare:')
    itemsTable.doubleAction = "showMarkMenu:"
    
    infoText.font = NSFont.fontWithName "Andale Mono", size:11.0
    logText.font  = NSFont.fontWithName "Andale Mono", size:11.0
    welcome = "\n\t\t\t\t\tWelcome to Guigna\n\t\tGUIGNA: the GUI of Guigna is Not by Apple  :)\n\n\t[Sync] to update from remote repositories.\n\tRight/double click a package to mark it.\n\t[Apply] to commit the changes to a [Shell].\n\n\tYou can try other commands typing in the yellow prompt.\n\tTip: Command-click to combine sources.\n\tWarning: keep the Guigna shell open!\n\n\n\t\t\t\tTHIS IS ONLY A PROTOTYPE.\n\n\n\t\t\t\tguido.soranzio@gmail.com"
    info welcome
    infoText.checkTextInDocument nil
    
    columns_menu = NSMenu.alloc.initWithTitle "ItemsColumnsMenu"
    view_columns_menu = NSMenu.alloc.initWithTitle "ItemsColumnsMenu"
    [columns_menu, view_columns_menu].each do |menu|
      itemsTable.tableColumns.each do |column|
        menu_item = NSMenuItem.alloc.initWithTitle(column.headerCell.stringValue, action:"toggle_table_column:", keyEquivalent:"")
        menu_item.target = self
        menu_item.representedObject = column
        menu.addItem menu_item
      end
      menu.delegate = self
    end
    itemsTable.headerView.setMenu columns_menu
    view_menu = NSApp.mainMenu().itemWithTitle("View")
    view_menu.submenu.addItem(NSMenuItem.separatorItem)
    columns_menu_item = NSMenuItem.alloc.initWithTitle("Columns", action: nil, keyEquivalent: "")
    columns_menu_item.submenu = view_columns_menu
    view_menu.submenu.addItem(columns_menu_item)
    
    @agent = GAgent.new
    @agent.app_delegate = self
    
    @sources = []
    @systems = []
    @scrapes = []
    @repos = []
    @items = []
    @all_packages = []
    @packages_index = {}
    @marked_items = []
    @marks_count = 0
    
    $APPDIR = File.expand_path("~/Library/Application Support/Guigna")
    system("mkdir -p '#{$APPDIR}'")
    system("touch '#{$APPDIR}/sync' '#{$APPDIR}/output'")
    %w[MacPorts Homebrew Fink pkgsrc FreeBSD Gentoo].each do |dir|
      system("mkdir -p '#{$APPDIR}/#{dir}'")
    end
    
    system("osascript -e 'tell application \"Terminal\" to close (windows whose name contains \"Guigna \")'")
    # framework 'ScriptingBridge'
    @terminal = SBApplication.applicationWithBundleIdentifier "com.apple.Terminal"
    guigna_function = "guigna() { osascript -e 'tell app \"Guigna-RubyMotion\"' -e \"open POSIX file \\\"#{$APPDIR}/$2\\\"\" -e 'end' &>/dev/null; }"
    init_script = "unset HISTFILE ; " + guigna_function
    @shell = terminal.doScript(init_script, in:nil)
    @shell.customTitle = "Guigna"
    @terminal.windows.each {|window| @shellWindow = window if window.name.include?("Guigna ")}
    
    self.sourceListBackgroundColor = sourcesOutline.backgroundColor
    self.linkTextAttributes = infoText.linkTextAttributes
    theme = defaults["Theme"]
    if theme.nil? || theme == "Default"
      @shell.backgroundColor = NSColor.colorWithCalibratedRed(1.0, green:1.0, blue:0.8, alpha:1.0) # light yellow
      @shell.normalTextColor = NSColor.colorWithCalibratedRed(0.0, green:0.0, blue:0.0, alpha:1.0)
      self.tableFont = NSFont.controlContentFontOfSize(NSFont.systemFontSizeForControlSize NSSmallControlSize)
      self.tableTextColor = NSColor.blackColor
      self.logTextColor = NSColor.blackColor
    else
      themesSegmentedControl.setSelectedSegment ["Default", "Retro"].index(theme)
      apply_theme(theme)
    end
    
    knownPaths = {MacPorts: "/opt/local", Homebrew: "/usr/local", pkgsrc: "/usr/pkg", Fink: "/sw"}
    knownPaths.each do |system, prefix|
      if File.exist? "#{prefix}_off"
        alert = NSAlert.alloc.init
        alert.setAlertStyle(NSCriticalAlertStyle)
        alert.setMessageText("Hidden system detected.")
        alert.setInformativeText("The path to #{system} is currently hidden by an \"_off\" suffix.")
        alert.addButtonWithTitle("Unhide")
        alert.addButtonWithTitle("Continue")
        if alert.runModal() == NSAlertFirstButtonReturn
          execute_as_root "mv #{prefix}_off #{prefix}"
        end
      end
    end
    
    port_path = MacPorts.prefix + "/bin/port"
    brew_path = Homebrew.prefix + "/bin/brew"
    paths = `/bin/bash -l -c "which port brew"`.split("\n")
    paths.each do |path|
      if path.end_with?("port")
        port_path = path
      elsif path.end_with?("brew")
        brew_path = path
      end
    end
    
    terminal.doScript("clear ; printf \"\\e[3J\" ; echo Welcome to Guigna! ; echo", in:@shell)
    
    if File.exist?(port_path) || File.exist?("#{$APPDIR}/MacPorts/PortIndex")
      defaults["MacPortsStatus"] = ON if defaults["MacPortsStatus"] == nil
      defaults["MacPortsParsePortIndex"] = true if defaults["MacPortsParsePortIndex"] == nil
    end
    if defaults["MacPortsStatus"] == ON
      macports = MacPorts.new(agent)
      macports.mode = :online if !File.exist?(port_path)
      if !(macports.mode == :online && !File.exist?("#{$APPDIR}/MacPorts/PortIndex"))
        @systems << macports
        if macports.cmd != port_path
          macports.prefix = File.dirname(File.dirname(port_path))
          macports.cmd = port_path
        end
      end
    end
    
    if File.exist?(brew_path)
      defaults["HomebrewStatus"] = ON if defaults["HomebrewStatus"] == nil
    end
    if defaults["HomebrewStatus"] == ON
      if File.exist?(brew_path)
        homebrew = Homebrew.new(agent)
        @systems << homebrew
        if homebrew.cmd != brew_path
          homebrew.prefix = File.dirname(File.dirnname(brew_path))
          homebrew.cmd = brew_path
        end
        if homebrew.casks?
          homebrewcasks = HomebrewCasks.new(agent)
          @systems << homebrewcasks
          homebrewcasks.prefix = homebrew.prefix
          homebrewcasks.cmd = brew_path + " cask"
        end
      end
    end
        
    if File.exist?("/sw/bin/fink")
      defaults["FinkStatus"] = ON if defaults["FinkStatus"] == nil
    end
    if defaults["FinkStatus"] == ON
      fink = Fink.new(agent)
      fink.mode = :online if !File.exist?("/sw/bin/fink")
      @systems << fink
    end
    
    if File.exist?("/usr/pkg/sbin/pkg_info") || File.exist?("#{$APPDIR}/pkgsrc/INDEX")
      if defaults["pkgsrcStatus"] == nil
        defaults["pkgsrcStatus"] = ON
        defaults["pkgsrcCVS"] = ON
      end
    end
    if defaults["pkgsrcStatus"] == ON
      pkgsrc = Pkgsrc.new(agent)
      pkgsrc.mode = :online if !File.exist?("/usr/pkg/sbin/pkg_info")
      @systems << pkgsrc
    end
    
    if File.exist?("#{$APPDIR}/FreeBSD/INDEX")
      defaults["FreeBSDStatus"] = ON if defaults["FreeBSDStatus"] == nil
    end
    if defaults["FreeBSDStatus"] == ON
      freebsd = FreeBSD.new(agent)
      freebsd.mode = :online
      @systems << freebsd
    end
    
    if File.exist?("/usr/local/bin/rudix")
      defaults["RudixStatus"] = ON if defaults["RudixStatus"] == nil
    end
    if defaults["RudixStatus"] == ON
      rudix = Rudix.new(agent)
      rudix.mode = :online if !File.exist?("/usr/local/bin/rudix")
      @systems << rudix
    end
    
    @systems << MacOSX.new(agent)
    
    defaults["iTunesStatus"] = ON if defaults["iTunesStatus"] == nil
    if defaults["iTunesStatus"] == ON
      itunes = ITunes.new(agent)
      @systems << itunes
    end
    
    defaults["ScrapesCount"] = 15 if defaults["ScrapesCount"] == nil
    @repos = [Native.new(agent)]
    @scrapes = [PkgsrcSE.new(agent), Freecode.new(agent), Debian.new(agent), CocoaPods.new(agent), PyPI.new(agent), RubyGems.new(agent), MacUpdate.new(agent), AppShopper.new(agent), AppShopperIOS.new(agent)]
    
    source1 = GSource.new("SYSTEMS")
    source1.categories = @systems.dup
    source2 = GSource.new("STATUS")
    source2.categories = [GSource.new("installed"), GSource.new("outdated"), GSource.new("inactive")]
    source3 = GSource.new("REPOS")
    source3.categories = @repos.dup
    source4 = GSource.new("SCRAPES")
    source4.categories = @scrapes.dup
    # sourcesController.content = NSMutableArray.alloc.initWithObjects(source1, GSource.new, source2, GSource.new, source3, GSource.new, source4, nil) # crash in RubyMotion
    sourcesController.content = [source1, GSource.new, source2, GSource.new, source3, GSource.new, source4]
    sourcesOutline.reloadData
    sourcesOutline.expandItem(nil, expandChildren:true)
    sourcesOutline.display
    
    @browser = SBApplication.applicationWithBundleIdentifier "com.apple.Safari"
    @selected_segment = "Info"
    @previous_segment = 0
    
    self.performSelectorInBackground("reload_all_packages", withObject:nil)
    
    @minute_timer = NSTimer.scheduledTimerWithTimeInterval(60.0, target:self, selector:"minute_check:", userInfo:nil, repeats:true)

    applyButton.enabled = false
    stopButton.enabled = false
    
    self.options self
  end
  
  def applicationDidBecomeActive(notification)
    if !self.shellWindow.nil? && self.shellWindow.name.include?("sudo")
      raiseShell(self)
    end
  end
      
  def applicationShouldTerminateAfterLastWindowClosed(app)
    true
  end
  
  def windowWillClose(sender)
    if self.ready
      system("osascript -e 'tell application \"Terminal\" to close (windows whose name contains \"Guigna \")'")
    end
  end
  
  def splitView(splitView, shouldAdjustSizeOfSubview:subview)
    subview != splitView.subviews.first
  end
  
  def outlineView(outlineView, isGroupItem:item)
    source = item.representedObject
    source.categories != nil and not source.kind_of? GSystem
  end
  
  def outlineView(outlineView, viewForTableColumn:tableColumn, item:item)
    source = item.representedObject
    # FIXME owner:self makes table items disappear
    if not item.parentNode.representedObject.kind_of? GSource
      return outlineView.makeViewWithIdentifier("HeaderCell", owner:nil)
    else
      if source.categories.nil? and item.parentNode.representedObject.kind_of? GSystem
        return outlineView.makeViewWithIdentifier("LeafCell", owner:nil)
      else
        return outlineView.makeViewWithIdentifier("DataCell", owner:nil)
      end
    end
  end
  
  def outlineView(outlineView, shouldShowOutlineCellForItem:item)
    return item.representedObject.kind_of? GSystem
  end
  
  def application(application, openFile:file)
    status "Ready."
    history = @shell.history.mutableCopy
    if !adminPassword.nil?
      sudo_command = "echo \"#{adminPassword}\" | sudo -S"
      history.gsub!(sudo_command, "sudo")
    end
    history.strip!.chop!
    log "#{history}\n"
    stopButton.setEnabled false
    status "Analyzing Shell output..."
    if history.start_with? "^C"  # TODO: || [history hasSuffix:@"Password:"]
      segmentedControl.setSelectedSegment -1
      update_tabview
      status "Shell: Interrupted."
      update_marked_source
      return true
    end
    # workaround for "this operation cannot be performed with encoding `UTF-8' because Apple's ICU does not support it"
    history = String.new(history).force_encoding("ASCII")
    sep = history.rindex("--->") # MacPorts
    sep2 = history.rindex("==>") # Homebrew # TODO ===> pkgsrc
    sep = sep2 if !sep2.nil? && !sep.nil? && sep2 > sep # most recent system
    sep2 = history.rindex("guigna --baton")
    sep = nil if !sep2.nil? && !sep.nil? && sep2 > sep # the last was a shell command
    sep = history.rindex("\n") if sep.nil?
    last_lines = history[sep..-1].split"\n"
    if last_lines.size > 1
      if last_lines[1].start_with? "Error"
        segmentedControl.setSelectedSegment -1
        update_tabview
        status "Shell: Error."
        update_marked_source
        return true
      end
    end
    status "Shell: OK."
    
    if file == "#{$APPDIR}/output"
      status "Analyzing committed changes..."
      if last_lines.size > 1
        if last_lines[-1].start_with? "sudo: 3 incorrect password attempts"
          status "Failed: incorrect password."
          update_marked_source
          return true
        end
      end
      # TODO review
      if marked_items.count > 0
        affected_systems = NSMutableSet.set
        marked_items.each do |item|
          affected_systems.addObject item.system
        end
        # refresh statuses and versions
        affected_systems.each do |system|
          system.items.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("status == '#{:inactive}'")).each do |pkg|
            itemsController.removeObject pkg
          end
          system.installed
          system.items.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("status == '#{:inactive}'")).each do |pkg|
            # RubyMotion crashes when not using an instance variable
            @predicate = itemsController.filterPredicate
            itemsController.addObject pkg
            itemsController.setFilterPredicate @predicate
          end
        end
        itemsTable.reloadData
        mark = nil
        marked_items.each do |item|
          mark = item.mark
          mark_name = mark.to_s.capitalize
          # TODO verify command did really complete
          if mark == :install
            @marks_count -= 1
            
          elsif mark == :uninstall
            @marks_count -= 1
            
          elsif mark == :deactivate
            @marks_count -= 1
            
          elsif mark == :upgrade
            @marks_count -= 1
            
          elsif mark == :fetch
            @marks_count -= 1
          end
          
          log "😺 #{mark_name} #{item.system.name} #{item.name}: DONE\n"
          item.mark = nil
          itemsTable.reloadData
        end
        update_marked_source
        if self.terminal.frontmost == false
          notification = NSUserNotification.alloc.init
          notification.title = "Ready."
          # notification.subtitle = "#{marks_count} changes applied"
          notification.informativeText = "The changes to the marked packages have been applied."
          notification.soundName = NSUserNotificationDefaultSoundName
          NSUserNotificationCenter.defaultUserNotificationCenter.deliverNotification notification
        end
      end
      status "Shell: OK."
      
    elsif file == "#{$APPDIR}/sync"
      self.performSelectorInBackground("reload_all_packages", withObject:nil)
    end
    return true
  end
  
  def reload_all_packages
    self.ready = false
    Dispatch::Queue.main.sync {
      itemsController.setFilterPredicate nil
      itemsController.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0, itemsController.arrangedObjects.count]))
      itemsController.setSortDescriptors nil
      tableProgressIndicator.startAnimation self
    }
    new_index = {}
    updated = 0
    new = 0
    previous_package = nil
    package = nil
    systems.each do |system|
      system_name = system.name
      Dispatch::Queue.main.sync {
        status "Indexing #{system_name}..."
      }
      system.list
      Dispatch::Queue.main.sync {
        itemsController.addObjects system.items
        itemsTable.display
      }
      if (packages_index.size > 0)  && !(system_name == "Mac OS X" || system_name == "FreeBSD" || system.name == "iTunes")
        system.items.each do |package|
          next if package.status == :inactive
          previous_package = packages_index[package.key]
          if previous_package.nil?
            package.status = :new
            new += 1
          elsif previous_package.version != package.version
            package.status = :updated
            updated += 1
          end
        end
      end
      new_index.addEntriesFromDictionary system.index # TODO: ruby
    end
    
    if packages_index.size > 0
      Dispatch::Queue.main.sync {
        sourcesOutline.setDelegate nil
        name = nil
        current_updated = sourcesController.content[2].categories.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("name BEGINSWITH 'updated'"))
        if current_updated.size > 0 && updated == 0
          sourcesController.content[2].mutableArrayValueForKey("categories").removeObject(current_updated[0])
        end
        if updated > 0
          name = "updated (#{updated})"
          if current_updated.size == 0
            updated_source = GSource.new(name)
            sourcesController.content[2].mutableArrayValueForKey("categories").addObject(updated_source)
          else
            current_updated[0].name = name
          end
        end
        current_new = sourcesController.content[2].categories.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("name BEGINSWITH 'new'"))
        if current_new.size > 0 && new == 0
          sourcesController.content[2].mutableArrayValueForKey("categories").removeObject current_new[0]
        end
        if new > 0
          name = "new (#{new})"
          if current_new.size == 0
            new_source = GSource.new(name)
            sourcesController.content[2].mutableArrayValueForKey("categories").addObject(new_source)
          else
            current_new[0].name = name
          end
        end
        sourcesOutline.setDelegate self
        @packages_index.clear
        @all_packages.clear
      }
      
    else
      Dispatch::Queue.main.sync {
        status "Indexing categories..."
        sourcesOutline.setDelegate nil
        sourcesController.content[0].categories.each do |system|
          system.categories = []
          cats = system.mutableArrayValueForKey("categories")
          system.categoriesList.each do |category|
            cats.addObject GSource.new(category)
          end
        end
        sourcesOutline.setDelegate self
        sourcesOutline.reloadData
        sourcesOutline.display
      }
    end
    systems.each do |system|
      # avoid adding duplicates of inactive packages already added by system.list
      @all_packages.addObjectsFromArray system.items.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("status != '#{:inactive}'"))
    end
    @packages_index.setDictionary new_index # TODO: rubyfy
    @marked_items.clear
    @marks_count = 0
    # TODO: remember marked items
    Dispatch::Queue.main.sync {
      itemsController.setSortDescriptors [NSSortDescriptor.sortDescriptorWithKey("status_order", ascending:false)]
      update_marked_source
      tableProgressIndicator.stopAnimation self
      applyButton.setEnabled false
      self.ready = true
      status "OK."
    }
  end
  
  def syncAction(sender)
    tableProgressIndicator.startAnimation self
    info "[Contents not yet available]"
    update_cmdline ""
    stopButton.enabled = true
    sync(sender)
  end
  
  def sync(sender)
    self.ready = false
    status "Syncing..."
    systems_to_update_async = []
    systems_to_update = []
    systems_to_list = []
    systems.each do |system|
      next if system.name == "Homebrew Casks"
      update_cmd = system.update_cmd
      if update_cmd.nil?
        systems_to_list << system
      elsif update_cmd.start_with? "sudo"
        systems_to_update_async << system
      else
        systems_to_update << system
      end
    end
    if systems_to_update_async.size > 0
      update_commands = systems_to_update_async.map &:update_cmd
      puts update_commands
      self.execute(update_commands.join(" ; "), with_baton:"sync")
    end
    if systems_to_update.size + systems_to_list.size > 0
      segmentedControl.setSelectedSegment -1
      update_tabview
      queue = Dispatch::Queue.concurrent('name.Guigna')
      systems_to_list.each do |system|
        status "Syncing #{system.name}..."
        queue.async {
          system.list
        }
      end
      systems_to_update.each do |system|
        status "Syncing #{system.name}..."        
        log "😺===> #{system.update_cmd.split(" ; ").reject {|line| line.start_with?("export")}.join(" ; ")}\n"
        queue.async {
          output = `#{system.update_cmd}`
          Dispatch::Queue.main.sync {
            log output
          }
        }
      end
      queue.barrier_async {
        if systems_to_update_async.size == 0
          self.performSelectorInBackground("reload_all_packages", withObject:nil)
        end
      }
    end
  end
  
  def outlineViewSelectionDidChange(outline)
    sourcesSelectionDidChange(outline)
  end
  
  def sourcesSelectionDidChange(outline)
    selected_sources = sourcesController.selectedObjects.mutableCopy
    tableProgressIndicator.startAnimation self
    selected_systems = (selected_sources & systems)
    selected_sources -= selected_systems
    selected_systems = systems.dup if selected_systems.size == 0
    selected_sources << sourcesController.content.first if selected_sources.size == 0 # SYSTEMS
    src = nil
    filter = searchField.stringValue
    itemsController.setFilterPredicate nil
    itemsController.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0, itemsController.arrangedObjects.count]))
    itemsController.setSortDescriptors nil
    first = true
    selected_sources.each do |source|
      src = source.name
      if source.kind_of? GScrape
        itemsTable.display
        source.page_number = 1
        update_scrape source
      else
        if first
          itemsController.addObjects @all_packages
        end
        selected_systems.each do |system|
          packages = []
          
          if src == "installed"
            if first
              status "Verifying installed packages..."
              itemsController.setFilterPredicate(NSPredicate.predicateWithFormat("status == '#{:uptodate}'"))
              itemsTable.display
            end
            packages = system.installed
            
          elsif src ==  "outdated"
            if first
              status "Verifying outdated packages..."
              itemsController.setFilterPredicate(NSPredicate.predicateWithFormat("status == '#{:outdated}'"))
              itemsTable.display
            end
            packages = system.outdated
            
          elsif src == "inactive"
            if first
              status "Verifying inactive packages..."
              itemsController.setFilterPredicate(NSPredicate.predicateWithFormat("status == '#{:inactive}'"))
              itemsTable.display
            end
            packages = system.inactive
            
          elsif src.start_with? "updated" or src.start_with? "new"
            src = src.split.first
            if first
              status "Verifying #{src} packages..."
              itemsController.setFilterPredicate(NSPredicate.predicateWithFormat("status == ':#{src}'"))
              itemsTable.display
              packages = itemsController.arrangedObjects.mutableCopy
            end
            
          elsif src.start_with? "marked"
            src = src.split.first
            if first
              status "Verifying marked packages..."
              itemsController.setFilterPredicate(NSPredicate.predicateWithFormat("mark != NIL"))
              itemsTable.display
              packages = itemsController.arrangedObjects.mutableCopy
            end
            
          elsif !(src == "SYSTEMS" || src == "STATUS" || src == "") # a category was selected
            itemsController.setFilterPredicate(NSPredicate.predicateWithFormat("categories CONTAINS[c] '#{src}'"))
            packages = system.items.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("categories CONTAINS[c] '#{src}'"))
          
          else # a system was selected
            itemsController.setFilterPredicate nil
            itemsTable.display
            packages = system.items
            if first && itemsController.selectedObjects.count == 0
              if sourcesController.selectedObjects.count == 1
                if sourcesController.selectedObjects.first.kind_of? GSystem
                  segmentedControl.setSelectedSegment 2 # shows System Log
                  update_tabview
                end
              end
            end
          end
          
          if first
            itemsController.setFilterPredicate nil
            itemsController.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0, itemsController.arrangedObjects.count]))
            first = false
          end
          
          itemsController.addObjects(packages)
          itemsTable.display
          if packages_index.size > 0
            packages.each do |package|
              if package.status != :inactive
                indexed_package = packages_index[package.key]
              else
                # TODO
                inactive_packages = all_packages.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("name == '#{package.name}' && installed == '#{package.installed}'"))
                indexed_package = (inactive_packages.count > 0) ? inactive_packages.first: nil
              end
              next if indexed_package.nil?
              mark = indexed_package.mark
              if !mark.nil?
                package.mark = mark
              end
            end
            itemsTable.display
          end
        end
      end
      searchField.stringValue = filter
      searchField.performClick self
      if selected_systems.size > 0
        itemsController.setSortDescriptors [NSSortDescriptor.sortDescriptorWithKey("status_order", ascending:false)]
      end
      tableProgressIndicator.stopAnimation self
      status("OK.") if self.ready && !(statusField.stringValue.start_with?("Executing") || statusField.stringValue.start_with?("Loading"))
    end
  end
  
  def tableViewSelectionDidChange(table)
    selected_items = itemsController.selectedObjects
    item = nil
    item = selected_items.first if selected_items.count > 0
    info "[No package selected]" if item.nil?
    if selected_segment == "Shell" || (selected_segment == "Log" && !item.nil? && !(item.system.nil?) && cmdline.stringValue == item.log)
      segmentedControl.setSelectedSegment 0
      @selected_segment = "Info"
    end
    update_tabview item
  end
  
  def toggle_table_column(sender)
    column = sender.representedObject
    column.setHidden !column.isHidden
  end
  
  def switchSegment(sender)
    @selected_segment = sender.labelForSegment(sender.selectedSegment)
    selected_items = itemsController.selectedObjects
    item = nil
    item = selected_items.first if selected_items.count > 0
    case selected_segment
    when "Shell", "Info", "Home", "Log", "Contents", "Spec", "Deps"
      update_tabview item
    end
  end
  
  def toggleShell(sender)
    selected_items = itemsController.selectedObjects
    item = nil
    item = selected_items.first if selected_items.count > 0
    if sender.state == NSOnState
      @previous_segment = segmentedControl.selectedSegment
      segmentedControl.setSelectedSegment -1
      @selected_segment = "Shell"
      update_tabview item
    else
      if previous_segment != -1
        segmentedControl.setSelectedSegment previous_segment
        update_tabview item
      end
    end
  end
  
  def update_tabview(item=nil)
    if segmentedControl.selectedSegment == -1
      shellDisclosure.state = NSOnState
      @selected_segment = "Shell"
    else
      shellDisclosure.state = NSOffState
      @selected_segment = segmentedControl.labelForSegment(segmentedControl.selectedSegment)
    end
    clearButton.hidden = (selected_segment != "Shell")
    screenshotsButton.hidden =  (!(item.source.kind_of? GScrape) || selected_segment != "Home") if !item.nil?
    moreButton.hidden =  (not item.source.kind_of? GScrape) if !item.nil?
    
    if selected_segment == "Home" || selected_segment == "Log"
      tabView.selectTabViewItemWithIdentifier "web"
      webView.display
      page = nil
      if !item.nil?
        if selected_segment == "Log"
          if item.source.name == "MacPorts" && item.categories.nil?
            item = packages_index[item.key]
          end
          page = item.log
        else
          item.homepage = item.home if item.homepage.nil?
          page = item.homepage
        end
      else # item is nil
        page = cmdline.stringValue
        page = page[8...-3] if page.start_with? "Loading"
        if !(page.include?("http") or page.include?("www"))
          page = "http://github.com/gui-dos/Guigna/"
        end
        if sourcesController.selectedObjects.count == 1
          if sourcesController.selectedObjects.first.kind_of? GSystem
            page = sourcesController.selectedObjects.first.log(nil)
          end
        end
      end
      if !item.nil? && !item.screenshots.nil? && screenshotsButton.state == NSOnState
        html = "<html><body>"
        item.screenshots.split.each do |url|
          html << "<img src=\"#{url}\" border=\"1\">"
        end
        html << "</body></html>"
        webView.mainFrame.loadHTMLString(html, baseURL:nil)
      else
        webView.mainFrameURL = page if page != webView.mainFrameURL
      end
    else
      if !item.nil?
        cmd = item.source.cmd.lastPathComponent
        if item.source.name == "Mac OS X"
          update_cmdline "#{cmd} #{item.id}"
        else
          update_cmdline "#{cmd} #{item.name}"
        end
      end
      if selected_segment == "Info" || selected_segment == "Contents" || selected_segment == "Spec" || selected_segment == "Deps"
        infoText.delegate = nil # avoid textViewDidChangeSelection notification
        tabView.selectTabViewItemWithIdentifier 'info'
        tabView.display
        if !item.nil?
          info ""
          status "Getting info..." unless statusField.stringValue.start_with? "Executing"
          
          if selected_segment == "Info"
            info item.info
            infoText.checkTextInDocument nil
            
          elsif selected_segment == "Contents"
            contents = item.contents
            if contents == "" or contents.end_with?("not installed.\n")
              info "[Contents not available]"
            else
              info "[Click on a path to open in Finder]\n" + contents +
              "\nUninstall command:\n" + item.uninstall_cmd
            end
            
          elsif selected_segment == "Spec"
            info item.cat
            infoText.checkTextInDocument nil
            
          elsif selected_segment == "Deps"
            tableProgressIndicator.startAnimation self
            status "Computing dependencies..."
            deps = item.deps
            dependents = item.dependents
            if deps == "" && dependents == ""
              info "[No dependencies]"
            elsif dependents != ""
              info deps + "\nDependents:\n" + dependents
            else
              info deps
            end
            tableProgressIndicator.stopAnimation self
          end
          infoText.delegate = self
          status "OK." unless statusField.stringValue.start_with? "Executing"
        end

      elsif selected_segment == "Shell"
        tabView.selectTabViewItemWithIdentifier "log"
        tabView.display
      end
    end
  end
  
  
  def clear(sender)
    logText.string = ""
  end
  
  def update_cmdline(cmd)
    cmdline.stringValue = cmd
    cmdline.display
  end
  
  def webView(sender, didStartProvisionalLoadForFrame:frame)
    update_cmdline "Loading #{webView.mainFrameURL}..."
    if self.ready && !statusField.stringValue.start_with?("Executing")
      status "Loading #{webView.mainFrameURL}..."
    end
  end
  
  def webView(sender, didFinishLoadForFrame:frame)
    if cmdline.stringValue.start_with? "Loading"
      update_cmdline cmdline.stringValue[8...-3]
      if self.ready && !statusField.stringValue.start_with?("Executing")
        status "OK."
      end
    else
      update_cmdline webView.mainFrameURL
    end
  end
  
  def webView(sender, didFailProvisionalLoadWithError:error, forFrame:frame)
    if cmdline.stringValue.start_with? "Loading"
      update_cmdline "Failed: " + cmdline.stringValue[8...-3]
      if self.ready && !statusField.stringValue.start_with?("Executing")
        status "OK."
      end
    else
      update_cmdline webView.mainFrameURL
    end
  end
  
  
  def update_scrape(scrape)
    segmentedControl.selectedSegment = 1
    @selected_segment = "Home"
    tabView.display
    status "Scraping #{scrape.name}..."
    scrapes_count = defaults["ScrapesCount"]
    pages_to_scrape = (scrapes_count.to_f / scrape.items_per_page).ceil
    for i in 1..pages_to_scrape
      scrape.refresh
      itemsController.addObjects scrape.items
      itemsTable.display
      scrape.page_number +=1 if i != pages_to_scrape
    end
    itemsController.setSelectionIndex(0) if itemsController.selectionIndex == NSNotFound
    self.window.makeFirstResponder itemsTable
    itemsTable.display
    screenshotsButton.setHidden false
    moreButton.setHidden false
    tableProgressIndicator.stopAnimation self
    update_tabview itemsController.selectedObjects.first
    if !statusField.stringValue.start_with? "Executing"
      status "OK."
    end
  end
  
  def moreScrapes(sender)
    scrape = sourcesController.selectedObjects.first
    scrape.page_number +=1
    update_scrape(scrape)
    itemsController.rearrangeObjects
  end
  
  def toggleScreenshots(sender)
    selected_items = itemsController.selectedObjects
    item = nil
    if selected_items.size > 0
      item = selected_items.first
      tableProgressIndicator.startAnimation self
      update_tabview item
      tableProgressIndicator.stopAnimation self
    end
  end
  
  def controlTextDidBeginEditing(notification)
  end
  
  def textViewDidChangeSelection(notification)
    selected_range = infoText.selectedRange
    storage = infoText.textStorage
    line = storage.string.substringWithRange(storage.string.paragraphRangeForRange(selected_range))
    
    if selected_segment == "Contents"
      file = line.strip
      # TODO: detect types
      if file.index(" -> ")  # Homebrew Casks
        file = file.split(" -> ")[1].stringByTrimmingCharactersInSet(NSCharacterSet.characterSetWithCharactersInString("'"))
      end
      file = file.split(" (")[0].stringByExpandingTildeInPath
      if file.end_with? ".nib"
        self.execute "/usr/bin/plutil -convert xml1 -o - #{file}"
      else
        NSWorkspace.sharedWorkspace.openFile file
      end
      
    elsif selected_segment == "Deps"
      package = line.strip
    end
  end
  
  def executeCmdLine(sender)
    selected_items = itemsController.selectedObjects
    item = nil
    item = selected_items.first if selected_items.count > 0
    input = cmdline.stringValue
    return if input.nil?
    tokens = input.split
    cmd = tokens.first
    if cmd.start_with?("http") || cmd.start_with?("www") # TODO
      update_cmdline("http://" + cmd) if cmd.start_with?("www")
      segmentedControl.setSelectedSegment 1
      @selected_segment = "Home"
      update_tabview
    else
      segmentedControl.selectedSegment = -1
      update_tabview item
      if cmd == "sudo"
        self.sudo(input[5..-1])
      else
        system = systems.find {|sys| sys.cmd.end_with?(cmd)}
        if !system.nil?
          cmd = system.cmd
          tokens[0] = cmd
        end
        if !cmd.start_with? "/"
          which = `/bin/bash -l -c "which #{cmd}"`
          if which.length != 0
            tokens[0] = which[0...-1]
            # else # TODO:show stderr
          end
        end
        cmd = tokens.join(" ")
        log("😺===> #{cmd}\n")
        status "Executing '#{cmd}'..."
        cmd = "export HOME=~ ; #{cmd}"
        output = `/bin/bash -l -c "#{cmd}"`
        status "OK."
        log output
      end
    end
  end
  
  def executeCommandsMenu(sender)
    selected_items = itemsController.selectedObjects
    item = nil
    item = selected_items.first if selected_items.count > 0
    title = sender.titleOfSelectedItem
    puts title
    system = item.system
    if system != nil
      command = system.available_commands.detect {|cmd_array| cmd_array[0] == title}[1]
      puts command
      command.gsub!("CMD", system.cmd.lastPathComponent)
      update_cmdline command
      executeCmdLine sender
    end
  end
  
  def execute(cmd, with_baton:baton)
    brief_cmd = cmd.split(" ; ").reject {|line| line.start_with?("sudo mv") || line.start_with?("export")}.join(" ; ")
    status "Executing '#{brief_cmd}' in the shell..."
    log "😺===> #{brief_cmd}\n"
    if baton == "relaunch"
      self.ready = false
      command = "#{cmd} ; osascript -e 'tell app \"Guigna-RubyMotion\"' -e 'quit' -e 'end' &>/dev/null ; osascript -e 'tell app \"Guigna-RubyMotion\"' -e 'activate' -e 'end' &>/dev/null &"
    else
      command = "#{cmd} ; guigna --baton #{baton}"
    end
    if !adminPassword.nil?
      command = command.gsub("sudo", "echo \"#{adminPassword}\" | sudo -S")
    end
    raiseShell(self)
    terminal.doScript(command, in:@shell)
  end
  
  def execute(cmd)
    self.execute(cmd, with_baton:"output")
  end
  
  def sudo(cmd, with_baton:baton)
    command = "sudo #{cmd}"
    self.execute(command, with_baton:baton)
  end
  
  def sudo(cmd)
    self.sudo(cmd, with_baton:"output")
  end
  
  def execute_as_root(cmd)
    system("osascript -e 'do shell script \"#{cmd}\" with administrator privileges'")
  end
  
  def minute_check(timer)
    if !self.shellWindow.nil? && self.shellWindow.name.include?("sudo")
      if NSApp.isActive
        raiseShell self
      end
      NSApp.requestUserAttention NSCriticalRequest
    end
  end
  
  def menuNeedsUpdate(menu)
    title = menu.title
    if title == "ItemsColumnsMenu"
      menu.itemArray.each do |menu_item|
        column = menu_item.representedObject
        menu_item.setState (column.isHidden ? NSOffState : NSOnState)
      end
    else
      selected_items = itemsController.selectedObjects.mutableCopy
      if itemsTable.clickedRow != -1
        selected_items << itemsController.arrangedObjects[itemsTable.clickedRow]
      end
      
      if title == "Mark"
        tableProgressIndicator.startAnimation self
        status "Analyzing selected items..."
        install_menu = menu.itemWithTitle "Install"
        marked_options = []
        current_options = []
        selected_items.each do |item|
          next if item.system.nil?
          item_system_options = item.system.options(item)
          available_options = item_system_options.split if !item_system_options.nil?
          marked_options = item.marked_options.split if !item.marked_options.nil?
          current_options = item.options.split if !item.options.nil?
          if marked_options.size == 0 && current_options.size > 0 # TODO
            marked_options = current_options.dup
            item.marked_options = marked_options.join(" ")
          end
          if not item_system_options.nil?
            options_menu = NSMenu.alloc.initWithTitle "Options"
            available_options.each do |available_option|
              options_menu.addItemWithTitle(available_option, action:"mark:", keyEquivalent:"")
              options = NSMutableSet.setWithArray marked_options
              options.unionSet NSSet.setWithArray(current_options)
              options.allObjects.each do |option|
                if option == available_option
                  options_menu.itemWithTitle(available_option).setState NSOnState
                end
              end
            end
            install_menu.setSubmenu options_menu
          else
            if install_menu.hasSubmenu
              install_menu.submenu.removeAllItems
              install_menu.setSubmenu nil
            end
          end
        end
        tableProgressIndicator.stopAnimation self
        status "OK."
      
      elsif title == "Commands"
        while commandsPopUp.numberOfItems > 1
          commandsPopUp.removeItemAtIndex 1
        end
        if selected_items.size == 0
          commandsPopUp.addItemWithTitle "[no package selected]"
        else
          item = selected_items.first # TODO
          if item.system != nil
            for cmd_array in item.system.available_commands
              commandsPopUp.addItemWithTitle(cmd_array[0])
            end
          end
        end
      end
    end
  end
  
  def marks(sender)
    showMarkMenu(sender)
    # TODO display marks summary
  end
  
  
  def showMarkMenu(sender)
    NSMenu.popUpContextMenu(markMenu, withEvent:NSApp.currentEvent, forView:itemsTable)
  end
  
  def mark(sender)
    selected_items = itemsController.selectedObjects.mutableCopy
    if itemsTable.clickedRow != -1
      selected_items << itemsController.arrangedObjects[itemsTable.clickedRow]
    end
    mark = nil
    selected_items.each do |item|
      title = sender.title

      if title == "Install" # TODO: rubyfy downcase.to_sym
        if !item.url.nil? && item.source.kind_of?(GScrape)
          NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString item.url)
          next
        end
        mark = :install
      elsif title == "Uninstall"
        mark = :uninstall
      elsif title == "Deactivate"
        mark = :deactivate
      elsif title == "Upgrade"
        mark = :upgrade
      elsif title == "Fetch"
        if !item.url.nil? && item.source.kind_of?(GScrape)
          NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString item.url)
          next
        end
        mark = :fetch
      elsif title == "Clean"
        mark = :clean
      elsif title == "Unmark"
        mark = nil
        if item.kind_of? GPackage
          item.marked_options = nil
          packages_index[item.key].marked_options = nil
        end
      else # variants/options submenu selected
        marked_options = []
        marked_options = item.marked_options.split if item.marked_options != nil
        if sender.state == NSOffState
          marked_options << title
        else
          marked_options.delete title
        end
        options = nil
        if marked_options.size > 0
          options = marked_options.join " "
        end
        item.marked_options = options
        @packages_index[item.key].marked_options = options
        mark = :install
      end
      if title == "Unmark"
        @marks_count -= 1 if !item.mark.nil?
      else
        @marks_count += 1 if item.mark.nil?
      end
      item.mark = mark
      if item.status == :inactive
        package = all_packages.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("name == '#{item.name}' && installed == '#{item.installed}'")).first
      else
        package = packages_index[item.key]
        if !package.nil?
          package.version = item.version
          package.options = item.options
        end
      end
      package.mark = mark if !package.nil?
    end
    update_marked_source
  end
  
  def update_marked_source
    sourcesOutline.setDelegate nil
    current_marked = sourcesController.content[2].categories.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("name BEGINSWITH 'marked'"))
    if current_marked.size > 0 && marks_count == 0
      sourcesController.content[2].mutableArrayValueForKey("categories").removeObject(current_marked.first)
    end
    if marks_count > 0
      name = "marked (#{marks_count})"
      if current_marked.size == 0
        marked_source = GSource.new("marked (#{marks_count})")
        sourcesController.content[2].mutableArrayValueForKey("categories").addObject(marked_source)
      else
        current_marked.first.name = name
      end
      NSApplication.sharedApplication.dockTile.setBadgeLabel "#{marks_count}"
    else
      NSApplication.sharedApplication.dockTile.setBadgeLabel nil
    end
    sourcesOutline.setDelegate self
    applyButton.setEnabled (marks_count > 0)
  end
  
  
  def apply(sender)
    self.ready = false
    @marked_items = all_packages.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("mark != NIL")).mutableCopy
    @marks_count = marked_items.size
    return if marks_count == 0
    applyButton.setEnabled false
    stopButton.setEnabled true
    itemsController.setSelectedObjects nil
    segmentedControl.setSelectedSegment -1
    @selected_segment = "Shell"
    update_tabview
    tasks = []
    marked_systems = NSMutableSet.set # TODO rubyfy
    marked_items.each {|item| marked_systems.addObject item.system }
    systems_dict = {}
    marked_systems.allObjects.each {|system| systems_dict[system.name] = [] }
    marked_items.each {|item| systems_dict[item.system.name] << item }
    prefixes = ["/opt/local", "/usr/local", "/sw", "/usr/pkg"]
    detected_prefixes = []
    prefixes.each {|prefix| detected_prefixes << prefix if File.exist?(prefix) }
    systems.each {|system| detected_prefixes.delete(system.prefix) if detected_prefixes.include?(system.prefix) }
    mark = nil
    marked_systems.allObjects.each do |system|
      system_tasks = []
      system_commands = []
      hides_others = false
      systems_dict[system.name].each do |item|
        mark = item.mark
        mark_name = mark.to_s.capitalize
        hides_others = false
        command = nil
        if mark == :install
          command = item.install_cmd
          hides_others = true unless item.system.name == "Homebrew Casks"
          
        elsif mark == :uninstall
          command = item.uninstall_cmd
          
        elsif mark == :deactivate
          command = item.deactivate_cmd
          
        elsif mark == :upgrade
          command = item.upgrade_cmd
          hides_others = true
          
        elsif mark == :fetch
          command = item.fetch_cmd
          
        elsif mark == :clean
          command = item.clean_cmd
        end
        if !command.nil?
          if defaults["DebugMode"] == true
            command = item.system.verbosified(command)
          end
          system_commands << command
        end
      end
      
      if hides_others && (systems.size > 1 || detected_prefixes.size > 0)
        systems.each do |other_system|
          next if other_system == system
          if !other_system.hide_cmd.nil? && other_system.hide_cmd != system.hide_cmd && !system_tasks.include?(other_system.hide_cmd) && File.exist?(other_system.prefix)
            tasks << other_system.hide_cmd
            system_tasks << other_system.hide_cmd
            # TODO: set GOnlineMode
          end
        end
        detected_prefixes.each do |prefix|
          tasks << "sudo mv #{prefix} #{prefix}_off"
        end
      end
      tasks.concat system_commands
      if hides_others && (systems.size > 1 || detected_prefixes.size > 0)
        systems.each do |other_system|
          next if other_system == system
          if !other_system.hide_cmd.nil? && other_system.hide_cmd != system.hide_cmd && !system_tasks.include?(other_system.unhide_cmd) && File.exist?(other_system.prefix)
            tasks << other_system.unhide_cmd
            system_tasks << other_system.unhide_cmd
          end
        end
        detected_prefixes.each do |prefix|
          tasks << "sudo mv #{prefix}_off #{prefix}"
        end
      end
    end
    self.execute tasks.join(" ; ")
  end
  
  def stop(sender)
    info "TODO"
  end
  
  
  def details(sender)
    info "TODO"
  end
  
  def raiseBrowser(sender)
    selected_items = itemsController.selectedObjects
    item = nil
    item = selected_items.first if selected_items.count > 0
    url = cmdline.stringValue
    url = "http://github.com/gui-dos/Guigna/" if item.nil? && !(url.start_with? "http")
    if url.start_with? "Loading"
      url = url[8...-3]
      update_cmdline url
      if !statusField.stringValue.start_with? "Executing"
        status "Launched in browser: #{url}"
      end
    elsif !url.start_with? "http"
      url = item.homepage != nil ? item.homepage : item.home
    end
    browser.activate
    if browser.windows.size == 0
      browser.windows.addObject browser.classForScriptingClass("document").alloc.init
    else
      browser.windows[0].tabs.addObject browser.classForScriptingClass("tab").alloc.init
      browser.windows[0].currentTab = browser.windows[0].tabs[browser.windows[0].tabs.size-1]
    end
    browser.windows[0].document.setURL NSURL.URLWithString(url)
  end
  
  def raiseShell(sender) # TODO create a new shell if the user closes the default
    @terminal.windows.each {|window| window.visible = false if !window.name.include?("Guigna ")}
    terminal.activate
    frame = tabView.frame
    frame.size.width += 0
    frame.size.height -= 3
    frame.origin.x = window.frame.origin.x + sourcesOutline.superview.frame.size.width + 1
    frame.origin.y = window.frame.origin.y + 22
    @terminal.windows.each {|window| @shellWindow = window if window.name.include?("Guigna ")}
    @shellWindow.frame = frame
    @terminal.windows.each {|window| window.frontmost = false if !window.name.include?("Guigna ")}
  end
  
  def open(sender)
    NSApp.activateIgnoringOtherApps true
    self.window.makeKeyAndOrderFront nil
    raiseShell self
  end
  
  def options(sender)
    window.beginSheet(optionsPanel,completionHandler:Proc.new { |returnCode| })
  end
  
  def closeOptions(sender)
    window.endSheet optionsPanel
  end
  
  def options_status(msg)
    if msg.end_with? "..."
      optionsProgressIndicator.startAnimation self
      if optionsStatusField.stringValue.start_with? "Executing"
        msg = "#{optionsStatusField.stringValue} #{msg}"
      end
    else
      optionsProgressIndicator.stopAnimation self
    end
    status msg
    msg = "" if msg == "OK."
    optionsStatusField.stringValue = msg
    optionsStatusField.display
  end
  
  def preferences(sender)
    self.ready = false
    optionsPanel.display
    if sender.kind_of?(NSSegmentedControl)
      theme = sender.labelForSegment(sender.selectedSegment)
      apply_theme theme
    else
      title = sender.title
      state = sender.state
      source = nil
      system = nil
      command = nil
      if state == NSOnState
        options_status "Adding #{title}..."
      
        if title == "Homebrew"
          command = "/usr/local/bin/brew"
          system = Homebrew.new(agent) if File.exists?(command)
        
        elsif title == "MacPorts"
          command = "/opt/local/bin/port"
          system = MacPorts.new(agent)
          if !File.exists?(command)
            self.execute "cd ~/Library/Application\\ Support/Guigna/Macports ; /usr/bin/rsync -rtzv rsync://rsync.macports.org/release/tarballs/PortIndex_darwin_12_i386/PortIndex PortIndex"
            system.mode = :online
          end
        
        elsif title == "Fink"
          command = "/sw/bin/fink"
          system = Fink.new(agent)
          system.mode = File.exists?(command) ? :offline : :online
        
        elsif title == "pkgsrc"
          command = "/usr/pkg/sbin/pkg_info"
          system = Pkgsrc.new(agent)
          system.mode = File.exists?(command) ? :offline : :online
        
        elsif title == "FreeBSD"
          system = FreeBSD.new(agent)
          system.mode = :online
        
        elsif title == "iTunes"
          system = ITunes.new(agent)
        end
      
        if !system.nil?
          @systems << system
          source = system
          systems_count = sourcesController.content.first.valueForKey("categories").count        
          sourcesController.content.first.mutableArrayValueForKey("categories").addObject source        
          # selecting the new system avoids freezing and memory peak
          sourcesController.setSelectionIndexPath NSIndexPath.indexPathWithIndex(0).indexPathByAddingIndex(systems_count)
          sourcesOutline.reloadData
          sourcesOutline.display
          self.sourcesSelectionDidChange(sourcesController.content.first.mutableArrayValueForKey("categories")[systems_count])
          itemsController.addObjects system.list
          itemsTable.display
          all_packages.addObjectsFromArray system.items
          packages_index.addEntriesFromDictionary system.index
          # duplicate code from reloalAllPackages
          source.categories = []
          cats = source.mutableArrayValueForKey("categories")
          system.categoriesList.each do |category|
            cats.addObject GSource.new(category)
          end
          sourcesOutline.reloadData
          sourcesOutline.display
          options_status "OK."
        else
          options_status "#{title}'s #{command} not detected."
        end
      else
        options_status "Removing #{title}..."
        filtered = sourcesController.content.first.categories.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("name == '#{title}'"))
        if filtered.size > 0
          source = filtered.first
          status = source.status
          if status == :on
            itemsController.removeObjects(@items.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("system.name == '#{title}'")))
            all_packages.filterUsingPredicate(NSPredicate.predicateWithFormat("system.name != '#{title}'"))
            for pkg in source.items
              packages_index.delete(pkg.key)
            end
            source.items.clear
            sourcesController.content.first.mutableArrayValueForKey("categories").removeObject(source)
            systems.removeObject(source)
          end
        end
        options_status "OK."
      end
    end
    self.ready = true
  end
  
  def apply_theme(theme)
    if theme == "Retro"
      self.window.setBackgroundColor NSColor.greenColor
      segmentedControl.superview.wantsLayer = true
      segmentedControl.superview.layer.backgroundColor = NSColor.blackColor.CGColor
      itemsTable.setBackgroundColor NSColor.blackColor
      itemsTable.setUsesAlternatingRowBackgroundColors false
      self.tableFont = NSFont.fontWithName "Andale Mono", size:11.0
      self.tableTextColor = NSColor.greenColor
      itemsTable.setGridColor NSColor.greenColor
      itemsTable.setGridStyleMask NSTableViewDashedHorizontalGridLineMask
      sourcesOutline.superview.superview.borderType = NSLineBorder # scroll view
      sourcesOutline.setBackgroundColor NSColor.blackColor
      segmentedControl.setSegmentStyle NSSegmentStyleSmallSquare
      commandsPopUp.setBezelStyle NSSmallSquareBezelStyle
      infoText.superview.superview.borderType = NSLineBorder
      infoText.setBackgroundColor NSColor.blackColor
      infoText.setTextColor NSColor.greenColor
      cyanLinkAttributes = linkTextAttributes.mutableCopy
      cyanLinkAttributes[NSForegroundColorAttributeName] = NSColor.cyanColor
      infoText.linkTextAttributes = cyanLinkAttributes
      logText.superview.superview.borderType = NSLineBorder
      logText.setBackgroundColor NSColor.blueColor
      logText.setTextColor NSColor.whiteColor
      self.logTextColor = NSColor.whiteColor
      statusField.setDrawsBackground true
      statusField.setBackgroundColor NSColor.greenColor
      cmdline.setBackgroundColor NSColor.blueColor
      cmdline.setTextColor NSColor.whiteColor
      clearButton.setBezelStyle NSSmallSquareBezelStyle
      screenshotsButton.setBezelStyle NSSmallSquareBezelStyle
      moreButton.setBezelStyle NSSmallSquareBezelStyle
      statsLabel.setDrawsBackground true
      statsLabel.setBackgroundColor NSColor.greenColor
      if @shell
        @shell.backgroundColor = NSColor.colorWithCalibratedRed(0.0, green:0.0, blue:1.0, alpha:1.0)
        @shell.normalTextColor = NSColor.colorWithCalibratedRed(1.0, green:1.0, blue:1.0, alpha:1.0)
      end
      
    else  # Default theme
      self.window.setBackgroundColor NSColor.windowBackgroundColor
      segmentedControl.superview.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor
      itemsTable.setBackgroundColor NSColor.whiteColor
      itemsTable.setUsesAlternatingRowBackgroundColors true
      self.tableFont = NSFont.controlContentFontOfSize(NSFont.systemFontSizeForControlSize NSSmallControlSize)
      self.tableTextColor = NSColor.blackColor
      itemsTable.setGridStyleMask NSTableViewGridNone
      itemsTable.setGridColor NSColor.gridColor
      sourcesOutline.superview.superview.borderType = NSGrooveBorder # scroll view
      sourcesOutline.setBackgroundColor self.sourceListBackgroundColor
      segmentedControl.setSegmentStyle NSSegmentStyleTexturedRounded
      commandsPopUp.setBezelStyle NSTexturedRoundedBezelStyle
      infoText.superview.superview.borderType = NSGrooveBorder
      infoText.setBackgroundColor(NSColor.colorWithCalibratedRed 0.82290249429999995, green:0.97448979589999996, blue:0.67131519269999995, alpha:1.0) # light green
      infoText.setTextColor NSColor.blackColor
      infoText.linkTextAttributes = linkTextAttributes
      logText.superview.superview.borderType = NSGrooveBorder
      logText.setBackgroundColor NSColor.colorWithCalibratedRed 1.0, green:1.0, blue:0.8, alpha:1.0 # light yellow
      logText.setTextColor NSColor.blackColor
      self.logTextColor = NSColor.blackColor
      statusField.setDrawsBackground false
      statusField.setTextColor NSColor.blackColor
      cmdline.setBackgroundColor(NSColor.colorWithCalibratedRed 1.0, green:1.0, blue:0.8, alpha:1.0)
      cmdline.setTextColor NSColor.blackColor
      clearButton.setBezelStyle NSTexturedRoundedBezelStyle
      screenshotsButton.setBezelStyle NSTexturedRoundedBezelStyle
      moreButton.setBezelStyle NSTexturedRoundedBezelStyle
      statsLabel.setDrawsBackground false
      if @shell
        @shell.backgroundColor = NSColor.colorWithCalibratedRed(1.0, green:1.0, blue:0.8, alpha:1.0)
        @shell.normalTextColor = NSColor.colorWithCalibratedRed(0.0, green:0.0, blue:0.0, alpha:1.0)
      end
    end
    defaults["Theme"] = theme
  end
  
  
  def toolsAction(sender)
    NSMenu.popUpContextMenu(toolsMenu, withEvent:NSApp.currentEvent, forView:itemsTable)
  end
  
  def tools(sender)
    title = sender.title
    case title
    when "Install Fink"
      self.execute(Fink.setup_cmd, with_baton:"relaunch")
      
    when "Remove Fink"
      self.execute(Fink.remove_cmd, with_baton:"relaunch")
      
    when "Install Homebrew"
      self.execute(Homebrew.setup_cmd, with_baton:"relaunch")
      
    when "Install Homebrew Cask"
      self.execute(HomebrewCasks.setup_cmd, with_baton:"relaunch")
      
    when "Remove Homebrew"
      self.execute(Homebrew.remove_cmd, with_baton:"relaunch")
      
    when "Install pkgsrc"
      self.execute(Pkgsrc.setup_cmd, with_baton:"relaunch")
      
    when "Fetch pkgsrc and INDEX"
      self.execute("cd ~/Library/Application\\ Support/Guigna/pkgsrc ; curl -L -O ftp://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/INDEX ; curl -L -O ftp://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc.tar.gz ; sudo tar -xvzf pkgsrc.tar.gz -C /usr", with_baton:"relaunch")
      
    when "Remove pkgsrc"
      self.execute(Pkgsrc.remove_cmd, with_baton:"relaunch")
      
    when "Fetch FreeBSD INDEX"
      self.execute("cd ~/Library/Application\\ Support/Guigna/FreeBSD ; curl -L -O ftp://ftp.freebsd.org/pub/FreeBSD/ports/packages/INDEX")
    
    when "Install Rudix"
      self.execute(Rudix.setup_cmd, with_baton:"relaunch")
        
    when "Fetch MacPorts PortIndex"
      self.execute("cd ~/Library/Application\\ Support/Guigna/Macports ; /usr/bin/rsync -rtzv rsync://rsync.macports.org/release/tarballs/PortIndex_darwin_12_i386/PortIndex PortIndex")
      
    when "Install Gentoo"
      self.execute(Gentoo.setup_cmd, with_baton:"relaunch")
      
    when "Build Gtk-OSX"
      self.execute(GtkOSX.setup_cmd, with_baton:"relaunch")
      
    when "Remove Gtk-OSX"
      self.execute(GtkOSX.remove_cmd, with_baton:"relaunch")
      
    end
  end
  
  def search(sender)
    window.makeFirstResponder searchField
  end
  
  
  def showHelp(sender) # TODO
    cmdline.stringValue = "http://github.com/gui-dos/Guigna/wiki/The-Guigna-Guide"
    segmentedControl.setSelectedSegment 1
    @selected_segment = "Home"
    update_tabview
  end
  
end


class GDefaultsTransformer < NSValueTransformer
  
  def self.transformedValueClass
    NSNumber.class
  end
  
  def self.allowsReverseTransformation
    true
  end
  
  def transformedValue(value)
    !(value == 0 || value.nil?)
  end
  
  def reverseTransformedValue(value)
    value == true ? 1 : 0
  end
  
end