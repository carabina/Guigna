# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class MacOSX < GSystem # TODO: review
  
  @prefix = "/usr/sbin"
  
  def initialize(agent=nil)
    super("Mac OS X", agent)
    @homepage = "http://support.apple.com/downloads/"
    @cmd = "#{@prefix}/pkgutil"
  end
  def list
    @index.clear
    @items.clear
    @items = self.installed
  end
  def installed
    pkgs = []
    pkgs_ids = `/usr/sbin/pkgutil --pkgs`.split("\n")
    history = load_plist(File.read("/Library/Receipts/InstallHistory.plist")).reverse!
    for dict in history
      keep_pkg = false
      ids = dict['packageIdentifiers']
      for pkg_id in ids
        if pkgs_ids.include?(pkg_id)
          keep_pkg = true
          pkgs_ids.delete pkg_id
        end
      end
      next if !keep_pkg
      name = dict['displayName']
      version = dict['displayVersion']
      category = dict['processName'].gsub(" ","").downcase
      if category == "installer"
        version = load_plist(`#{cmd} --pkg-info-plist #{ids[0]}`)["pkg-version"]
      end
      pkg = GPackage.new(name, nil, self, :uptodate)
      pkg.id = ids.join(' ')
      pkg.categories = category
      pkg.description = pkg.id
      pkg.installed = version # TODO: pkg.version
      pkgs << pkg
      # @index[pkg.key] = pkg
      # TODO verify installed
    end
    pkgs
  end
  
  # TODO
  def outdated
    pkgs = []
    return pkgs
  end
  
  def info(pkg)
    output = ""
    pkg.id.split.each do |id|
      output << `#{cmd} --pkg-info #{id}` + "\n"
    end
    output
  end
  
  def home(pkg)
    homepage = "http://support.apple.com/downloads/"
    if pkg.categories == "storeagent" || pkg.categories == “storedownloadd”
      url = "http://itunes.apple.com/lookup?bundleId=#{pkg.id}"
      data = NSData.dataWithContentsOfURL(NSURL.URLWithString url)
      results = NSJSONSerialization.JSONObjectWithData(data, options:0, error:nil)["results"]
      if results.size > 0
        pkg_id = results[0]["trackId"].to_s
        main_div = agent.nodes_for_url("http://itunes.apple.com/app/id" + pkg_id, xpath:"//div[@id=\"main\"]").first
        links = main_div["//div[@class=\"app-links\"]/a"]
        screenshots_imgs = main_div["//div[contains(@class, \"screenshots\")]//img"]
        pkg.screenshots = screenshots_imgs.map {|img| img['@src']}.join(" ")
        homepage = links[0].href
        homepage = links[1].href if homepage == "http://"
      end
    end
    return homepage
  end
  
  def log(pkg)
    page = "http://support.apple.com/downloads/"
    if !pkg.nil?
      if pkg.categories == "storeagent" || pkg.categories == “storedownloadd”
        url = "http://itunes.apple.com/lookup?bundleId=#{pkg.id}"
        data = NSData.dataWithContentsOfURL(NSURL.URLWithString url)
        results = NSJSONSerialization.JSONObjectWithData(data, options:0, error:nil)["results"]
        if results.size > 0
          pkg_id = results[0]["trackId"].to_s
          page = "http://itunes.apple.com/app/id" + pkg_id
        end
      end
    end
    return page
  end
  
  def contents(pkg)
    contents = ""
    pkg.id.split.each do |id|
      plist = load_plist `#{cmd} --pkg-info-plist #{id}`
      files = `#{@cmd} --files #{id}`.split("\n")
      files.each do |file|
        contents << NSString.pathWithComponents([plist['volume'], plist['install-location'], file]) +"\n"
      end
    end
    contents
  end
  
  
  def uninstall_cmd(pkg)
    # SEE: https://github.com/caskroom/homebrew-cask/blob/master/lib/cask/pkg.rb
    commands = []
    dirs_to_delete = []
    for pkg_id in pkg.id.split
      plist = load_plist `#{cmd} --pkg-info-plist #{pkg_id}`
      dirs = `#{cmd} --only-dirs --files #{pkg_id}`.split("\n")
      for dir in dirs
        dir_path = NSString.pathWithComponents([plist['volume'], plist['install-location'], dir])
        
        if (File.stat(dir_path).uid != 0 && !dir_path.start_with?('/usr/local')) \
          || dir_path.include?(pkg.name) || dir_path.include?('.') \
          || dir_path.start_with?('/opt/')
          
          if dirs_to_delete.select {|d| dir_path.include?(d)}.size == 0
            dirs_to_delete << dir_path
            commands << "sudo rm -r \"#{dir_path}\""
          end
        end
      end
      files = `#{cmd} --files #{pkg_id}`.split("\n") # links are not detected with --only-files
      for file in files
        file_path = NSString.pathWithComponents([plist['volume'], plist['install-location'], file])
        unless File.directory?(file_path)
          if dirs_to_delete.select {|d| file_path.include?(d)}.size == 0
            commands << "sudo rm \"#{file_path}\""
          end
        end
      end
      commands << "sudo #{cmd} --forget #{pkg_id}"
    end
    return commands.join(" ; ")
  end
  # TODO: disable Launchd daemons, clean Application Support, Caches, Preferences
  # SEE: https://github.com/caskroom/homebrew-cask/blob/master/lib/cask/artifact/pkg.rb
end
