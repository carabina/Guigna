# require 'GAdditions'
# require 'GLibrary'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class Rudix < GSystem
  
  @prefix = '/usr/local'
  
  def initialize(agent=nil)
    super("Rudix", agent)
    @homepage = "http://rudix.org/"
    @cmd = "#{@prefix}/bin/rudix"
  end
  
  def self.clamped_os_version
    os_version = G.os_version
    if os_version < "10.6" || os_version > "10.9"
      os_version = "10.9"
    end
  end
  
  def list
    @index.clear
    @items.clear
    if self.mode == :online
      manifest = NSString.stringWithContentsOfURL(NSURL.URLWithString("http://rudix.org/download/2014/10.9/00MANIFEST.txt"), encoding:NSUTF8StringEncoding, error:nil)
    else
      command = "#{cmd} search"
      osx_version = Rudix.clamped_os_version()
      if G.os_version != osx_version
        command = "export OSX_VERSION=#{osx_version} ; #{cmd} search"
      end
      manifest = `#{command}`
    end
    manifest.split("\n").each do |line|
      components = line.split "-"
      name = components[0]
      if components.size == 4
        name = name + "-" + components[1]
        components.delete_at(1)
      end
      version = components[1]
      version = version + "-" + components[2].split(".").first
      pkg = GPackage.new(name, version, self, :available)
      if !self[name].nil?
        prev_pkg = @items.delete self[name]
      end
      @items << pkg
      self[name] = pkg
    end
    self.installed # update index status
    @items
  end
    
  def installed
    if self.hidden?
      return @items.select {|pkg| pkg.status != :available}
    end
    pkgs = []
    return pkgs if self.mode == :online
    @items.each do |pkg|
      status = pkg.status
      pkg.installed = nil
      pkg.status = :available if status != :updated and status != :new
    end
    # self.outdated # update status of outdated packages
    output = `export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd}`
    output.split("\n").each do |line|
      name = line[line.rindex(".")+1..-1]
      pkg = self[name]
      latest_version = (pkg.nil? || pkg.version.nil?) ? nil : pkg.version.dup
      if pkg.nil?
        pkg = GPackage.new(name, latest_version, self, :uptodate)
        self[name] = pkg
      else
        if pkg.status == :available
          pkg.status = :uptodate
        end
      end
      pkg.installed = ""  # TODO
      pkgs << pkg
    end
    return pkgs
  end
  
  def home(item)
    "http://rudix.org/packages/#{item.name}.html"
  end
  
  def log(item)
    if !item.nil?
      "https://github.com/rudix-mac/rudix/commits/master/Ports/#{item.name}"
    else
      "https://github.com/rudix-mac/rudix/commits/"
    end
  end
  
  def contents(pkg)
    if !pkg.installed.nil?
      `export HOME=~ ; export PATH=#{ENV["PATH"]} ;  #{cmd} --files #{pkg.name}`
    else
      ""
    end
  end
  
  def cat(pkg)
    return NSString.stringWithContentsOfURL(NSURL.URLWithString("https://raw.githubusercontent.com/rudix-mac/rudix/master/Ports/#{pkg.name}/Makefile", encoding:NSUTF8StringEncoding, error:nil))
  end
  
  def install_cmd(pkg)
    command = "#{cmd} install #{pkg.name}"
    osx_version = Rudix.clamped_os_version()
    if G.os_version != osx_version
      command = "OSX_VERSION=#{osx_version} #{command}"
    end
    "sudo #{command}"
  end
  def uninstall_cmd(pkg)
    "sudo #{cmd} remove #{pkg.name}"
  end
  def fetch_cmd(pkg)
    command = "cd ~/Downloads ; #{cmd} --download #{pkg.name}"
    osx_version = Rudix.clamped_os_version()
    if G.os_version != osx_version
      command = "cd ~/Downloads ; OSX_VERSION=#{osx_version} #{cmd} --download #{pkg.name}"
    end
    command
  end
  
  def hide_cmd
    "sudo mv #{prefix} #{prefix}_off"
  end
  def unhide_cmd
    "sudo mv #{prefix}_off #{prefix}"
  end
  def self.setup_cmd
    command = "curl -s https://raw.githubusercontent.com/rudix-mac/rpm/master/rudix.py | sudo python - install rudix"
    osx_version = Rudix.clamped_os_version()
    if G.os_version != osx_version
      command = "curl -s https://raw.githubusercontent.com/rudix-mac/rpm/master/rudix.py | sudo OSX_VERSION=#{osx_version} python - install rudix"
    end
    command
  end
  def self.remove_cmd
    "sudo #{self.prefix}/bin/rudix -R"
  end
  
end
