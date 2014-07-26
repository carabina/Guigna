# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class MacPorts < GSystem
  
  @prefix = '/opt/local'
  
  def initialize(agent=nil)
    super("MacPorts", agent)
    @homepage = "http://www.macports.org"
    @cmd = "#{self.prefix}/bin/port"
  end
  
  def list
    @index.clear
    @items.clear
    pkgs = []
    if self.agent.app_delegate.defaults['MacPortsParsePortIndex'] == false
      list = `export HOME=~ ; #{cmd} list`.split("\n")
      for line in list
        components = line.split("@")
        name = components.first.strip
        components = components[1].split
        version = components[0]
        categories = components.last.split("/").first
        pkg = GPackage.new(name, version, self, :available)
        # pkg = GPackage.new(name, "#{version}_#{revision}", self, :available)
        pkg.categories = categories
        pkgs << pkg
        @items << pkg
        self[name] = pkg
      end
    else  
      if self.mode == :online
        portindex = NSString.stringWithContentsOfFile(File.expand_path("~/Library/Application Support/Guigna/MacPorts/PortIndex"), encoding:NSUTF8StringEncoding, error:nil)
      else
        portindex = NSString.stringWithContentsOfFile("#{prefix}/var/macports/sources/rsync.macports.org/release/tarballs/ports/PortIndex", encoding:NSUTF8StringEncoding, error:nil)
      end
      s = NSScanner.scannerWithString(portindex) # MacRuby's StringScanner too slow
      s.setCharactersToBeSkipped NSCharacterSet.characterSetWithCharactersInString("")
      endsCharacterSet = NSMutableCharacterSet.whitespaceAndNewlineCharacterSet
      endsCharacterSet.addCharactersInString "}"
      str = Pointer.new(:id)
      loop do
        break if !s.scanUpToString(" ", intoString:str)
        name = str[0]
        s.scanUpToString("\n", intoString:nil)
        s.scanString("\n", intoString:nil)
        begin
          s.scanUpToString(' ', intoString:str)
          key = str[0]
          s.scanString(' ', intoString:nil)
          s.scanUpToCharactersFromSet(endsCharacterSet, intoString:str)
          value = str[0].mutableCopy
          while value.include?('{')
            value.sub!('{', '')
            value << str[0] if s.scanUpToString('}', intoString:str)
            s.scanString('}', intoString:nil)
          end
          case key
          when 'version'
            version = value
          when 'revision'
            revision = value
          when 'categories'
            categories = value
          when 'description'
            description = value
          when 'homepage'
            homepage = value
          when 'license'
            license = value
          end
          if s.scanString("\n", intoString:nil)
            break
          end
          s.scanString(' ', intoString:nil)
        end while true
        pkg = GPackage.new(name, "#{version}_#{revision}", self, :available)
        pkg.categories = categories
        pkg.description = description
        pkg.license = license
        pkg.homepage = homepage if self.mode == :online
        pkgs << pkg
        @items << pkg
        self[name] = pkg
      end
    end
    self.installed # update status
    pkgs
  end

  
  def installed
    if self.hidden?
      return @items.select {|pkg| pkg.status != :available}
    end
    pkgs = []
    return pkgs if self.mode == :online
    list = `export HOME=~ ; #{cmd} installed`.split("\n")
    list.shift
    inactive = self.items.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("status == '#{:inactive}'"))
    @items.removeObjectsInArray(inactive)
    self.agent.app_delegate.all_packages.removeObjectsInArray(inactive) # TODO: ugly
    @items.each do |pkg|
      status = pkg.status
      pkg.installed = nil
      pkg.status = :available if status != :updated and status != :new
    end
    self.outdated # index outdated ports
    list.each do |line|
      components = line.strip.split
      name = components.first
      version =  components[1][1..-1]
      variants = nil
      sep = version.index "+"
      if !sep.nil?
        variants = version[sep+1..-1].split("+").join(" ")
        version = version[0...sep]
      end
      if !variants.nil?
        version << " +#{variants.gsub(' ','+')}"
      end
      status = components.count == 2 ? :inactive : :uptodate
      pkg = self[name]
      latest_version = (pkg.nil? || pkg.version.nil?) ? nil : pkg.version.dup
      if status == :inactive
        pkg = nil
      end
      if pkg.nil?
        pkg = GPackage.new(name, latest_version, self, status)
        pkg.installed = version
        if status != :inactive
          self[name] = pkg
        else
          @items << pkg
          self.agent.app_delegate.all_packages << pkg # TODO: ugly
        end
      else
        pkg.status = status if pkg.status == :available
      end
      pkg.installed = version
      pkg.options = variants
      pkgs << pkg
    end
    pkgs
  end
  
  def outdated
    if self.hidden?
      return @items.select {|pkg| pkg.status == :outdated}
    end
    pkgs = []
    return pkgs if self.mode == :online
    list = `export HOME=~ ; #{cmd} outdated`.split("\n")
    list.shift
    list.each do |line|
      components = line.split(" < ").first.split
      name = components.first
      version = components.last
      pkg = self[name]
      latest_version = (pkg.nil? || pkg.version.nil?) ? nil : pkg.version.dup
      if pkg.nil?
        pkg = GPackage.new(name, latest_version, self, :outdated)
        pkg.installed = version
        self[name] = pkg
      else
        pkg.status = :outdated
      end
      pkgs << pkg
    end
    return pkgs
  end
  
  def inactive
    if self.hidden?
      return @items.select {|pkg| pkg.status == inactive}
    end
    pkgs = []
    return pkgs if self.mode == :online
    return self.installed.select {|pkg| pkg.status == :inactive}
  end
  
  # TODO: review :online
  def info(pkg)
    if self.hidden?
      return super
    end
    if self.mode == :online
      # TODO: format keys and values
      info = agent.nodes_for_url("http://www.macports.org/ports.php?by=name&substr=#{pkg.name}", xpath:"//div[@id=\"content\"]/dl").first.stringValue
      keys = agent.nodes_for_url("http://www.macports.org/ports.php?by=name&substr=#{pkg.name}", xpath:"//div[@id=\"content\"]/dl//i")
      keys.each do |key|
        string_value = key.stringValue
        info.gsub!(string_value, "\n\n#{string_value}\n")
      end
      return info
    else
      columns = agent.app_delegate.shell_columns
      `export HOME=~ ; export COLUMNS=#{columns} ; #{cmd} info #{pkg.name}`
    end
  end
  
  def home(pkg)
    if self.hidden?
      cat(pkg).split("\n").each do |line|
        if line.include?("homepage")
          homepage = line[8..-1].strip
          if homepage.start_with?("http")
            return homepage
          end
        end
      end
      return log(pkg)
    elsif self.mode == :online
      pkg.homepage
    else
      `export HOME=~ ; #{cmd} -q info --homepage #{pkg.name}`[0...-1]
    end
  end
  
  def log(pkg)
    !pkg.nil? ? "http://trac.macports.org/log/trunk/dports/#{pkg.categories.split.first}/#{pkg.name}/Portfile" : "http://trac.macports.org/timeline"
  end
  
  def cat(pkg)
    if self.hidden? || self.mode == :online
      NSString.stringWithContentsOfURL(NSURL.URLWithString("http://trac.macports.org/browser/trunk/dports/#{pkg.categories.split(' ')[0]}/#{pkg.name}/Portfile?format=txt", encoding:NSUTF8StringEncoding, error:nil))
    else
      `export HOME=~ ; #{cmd} cat #{pkg.name}`
    end
  end
  
  def deps(pkg)
    if self.hidden? || self.mode == :online
      "[Cannot compute the dependencies now]" # TODO
    else
      `export HOME=~ ; #{cmd} rdeps --index #{pkg.name}`
    end
  end
  
  def dependents(pkg)
    if self.hidden? || self.mode == :online
      "" # TODO
    else
      `export HOME=~ ; #{cmd} dependents #{pkg.name}`
    end
  end
  
  def contents(pkg)
    if self.hidden? || self.mode == :online
      "[Not available]" # TODO
    else
      `export HOME=~ ; #{cmd} contents #{pkg.name}`
    end
  end
  
  def options(pkg)
    variants = nil
    output = `export HOME=~ ; #{cmd} info --variants #{pkg.name}`.strip
    variants = output[10..-1].gsub(", ", " ") if output.length > 10
    variants
  end
  
  def install_cmd(pkg)
    variants = pkg.marked_options
    variants = variants.nil? ? "" : "+" + variants.gsub(" ", "+")
    "sudo #{cmd} install #{pkg.name} #{variants}"
  end
  def uninstall_cmd(pkg)
    if pkg.status == :outdated || pkg.status == :updated
      "sudo #{cmd} -f uninstall #{pkg.name} ; sudo #{cmd} clean --all #{pkg.name}"
    else
      "sudo #{cmd} -f uninstall #{pkg.name} @#{pkg.installed}"
    end
  end
  def deactivate_cmd(pkg)
    "sudo #{cmd} deactivate #{pkg.name}"
  end
  def upgrade_cmd(pkg)
    "sudo #{cmd} upgrade #{pkg.name}"
  end
  def fetch_cmd(pkg)
    "sudo #{cmd} fetch #{pkg.name}"
  end
  def clean_cmd(pkg)
    "sudo #{cmd} clean --all #{pkg.name}"
  end
  
  def update_cmd
    if self.mode == :online
      "sudo cd ; cd ~/Library/Application\\ Support/Guigna/Macports ; /usr/bin/rsync -rtzv rsync://rsync.macports.org/release/tarballs/PortIndex_darwin_13_i386/PortIndex PortIndex"
    else
      "sudo #{cmd} -d selfupdate"
    end
  end
  def hide_cmd
    "sudo mv #{prefix} #{prefix}_off"
  end
  def unhide_cmd
    "sudo mv #{prefix}_off #{prefix}"
  end
end
