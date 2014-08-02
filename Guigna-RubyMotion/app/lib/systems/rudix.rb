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
  
  def clamped_os_version
    os_version = G.os_version
    if os_version < "10.6" || os_version > "10.9"
      os_version = "10.9"
    end
  end
  
  def list
    @index.clear
    @items.clear
    command = "#{cmd} search"
    osx_version = clamped_os_version()
    if G.os_version != osx_version
      command = "export OSX_VERSION=#{osx_version} ; #{cmd} search"
    end
    output = `#{command}`
    output.split("\n").each do |line|
      components = line.split "-"
      name = components[0]
      if components.size == 4
        name = name + "-" + components[1]
        components.delete_at(1)
      end
      version = components[1]
      version = version + "-" + components[2].split(".").first
      pkg = GPackage.new(name, version, self, :available)
      @items << pkg
      self[name] = pkg
    end
    self.installed # update index status
    @items
  end
    
      
  def refresh
    pkgs = []
    url = "http://rudix.org/download/2014/10.9/"
    links = agent.nodes_for_url(url, xpath:"//tbody//tr//a")
    decimalCharSet = NSCharacterSet.decimalDigitCharacterSet
    links.each do |link|
      name = link.stringValue
      next if name.start_with? 'Parent Dir' or name.include?("MANIFEST") or name.include?("ALIASES")
      sep = name.index "-"
      version = name[sep+1..-1]
      version = version[0...-4]
      if not decimalCharSet.characterIsMember(version[0].ord)
        sep2 = version.index("-")
        version = version[sep2+1..-1]
        sep += sep2+1
      end
      name = name[0...sep]
      pkg = GItem.new(name, version, self, :available)
      pkg.homepage = "http://rudix.org/packages/#{pkg.name}.html"
      pkgs << pkg
    end
    @items = pkgs
  end
  
  def log(item)
    if !item.nil?
      "https://github.com/rudix-mac/rudix/commits/master/Ports/#{item.name}"
    else
      "https://github.com/rudix-mac/rudix/commits/"
    end
  end
  
  def self.setup_cmd
    "curl -s https://raw.githubusercontent.com/rudix-mac/rpm/master/rudix.py | sudo python - install rudix"
  end
  
end
