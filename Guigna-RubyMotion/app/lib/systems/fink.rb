# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class Fink < GSystem
  
  @prefix = '/sw'
  
  def initialize(agent=nil)
    super("Fink", agent)
    @homepage = "http://www.finkproject.org"
    @cmd = "#{@prefix}/bin/fink"
  end
  
  def list
    @index.clear
    @items.clear
    if self.mode == :online
      nodes = agent.nodes_for_url("http://pdb.finkproject.org/pdb/browse.php", xpath:"//tr[@class=\"package\"]")
      nodes.each do |node|
        data_rows = node["td"]
        description = data_rows[2].stringValue
        next if description.start_with? "[virtual"
        name = data_rows.first.stringValue
        version = data_rows[1].stringValue
        pkg = GPackage.new(name, version, self, :available)
        pkg.description = description
        @items << pkg
        self[name] = pkg
      end
    else
      output = `#{cmd} list --tab`
      state = nil
      status = nil
      output.split("\n").each do |line|
        components = line.split("\t")
        description = components[3]
        next if description.start_with? "[virtual"
        name = components[1]
        version = components[2]
        state = components.first.strip
        status = :available
        if state == "i" || state == "p"
          status = :uptodate
        elsif state == "(i)"
          status = :outdated
        end
        pkg = GPackage.new(name, version, self, status)
        pkg.description = description
        @items << pkg
        self[name] = pkg
      end
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
      pkg.status = :available if status != :updated and status != :new # TODO: !pkg.description.start_with?("[virtual")
    end
    output = `#{prefix}/bin/dpkg-query --show`.split("\n")
    output.each do |line|
      components = line.split("\t")
      name = components[0]
      version = components[1]
      status = :uptodate
      pkg = self[name]
      latest_version = (pkg.nil? || pkg.version.nil? ) ? nil : pkg.version.dup
      if pkg.nil?
        pkg = GPackage.new(name, latest_version, self, status)
        self[name] = pkg
      else
        pkg.status = status if pkg.status == :available
      end
      pkg.installed = version
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
    output = `#{cmd} list --outdated --tab`.split("\n")
    output.each do |line|
      components = line.split("\t")
      name = components[1]
      version = components[2]
      description = components[3]
      pkg = self[name]
      if pkg.nil?
        pkg = GPackage.new(name, version, self, :outdated)
        self[name] = pkg
      else pkg.status = :outdated
      end
      pkg.description = description
      pkgs << pkg
    end
    pkgs
  end
  
  def info(pkg)
    if self.hidden?
      return super
    end
    if self.mode == :online
      nodes = agent.nodes_for_url("http://pdb.finkproject.org/pdb/package.php/#{pkg.name}", xpath:"//div[@class=\"desc\"]")
      if nodes.size == 0
        return "[Info not available]"
      else
        return nodes.first.stringValue
      end
    else
      `#{cmd} dumpinfo #{pkg.name}`
    end
  end
  
  def home(pkg)
    nodes = agent.nodes_for_url("http://pdb.finkproject.org/pdb/package.php/#{pkg.name}", xpath:"//a[contains(@title, \"home\")]")
    if nodes.size == 0
      return "[Homepage not available]"
    else
      return nodes.first.stringValue
    end
  end
  
  def log(pkg)
    if !pkg.nil?
      "http://pdb.finkproject.org/pdb/package.php/#{pkg.name}"
    else
      "http://www.finkproject.org/package-updates.php"
      # "http://github.com/fink/fink/commits/master"
    end
  end
  
  def contents(pkg)
    ""
  end
  
  def cat(pkg)
    if self.hidden? || self.mode == :online
      nodes = agent.nodes_for_url("http://pdb.finkproject.org/pdb/package.php/#{pkg.name}", xpath:"//a[contains(@title, \"info\")]")
      if nodes.size == 0
        return "[.info not reachable]"
      else
        cvs = nodes.first.stringValue
        info = NSString.stringWithContentsOfURL(NSURL.URLWithString("http://fink.cvs.sourceforge.net/fink/#{cvs}", encoding:NSUTF8StringEncoding, error:nil))
        return info
      end
    else
      `#{@cmd} dumpinfo #{pkg.name}`
    end
  end
  
  def install_cmd(pkg)
    "sudo #{cmd} install #{pkg.name}"
  end
  def uninstall_cmd(pkg)
    "sudo #{cmd} remove #{pkg.name}"
  end
  def upgrade_cmd(pkg)
    "sudo #{cmd} update #{pkg.name}"
  end
  
  def update_cmd
    self.mode == :online ? nil : "sudo #{cmd} selfupdate"
  end
  def hide_cmd
    "sudo mv #{prefix} #{prefix}_off"
  end
  def unhide_cmd
    "sudo mv #{prefix}_off #{prefix}"
  end
  
  def self.setup_cmd
    "sudo mv /usr/local /usr/local_off ; sudo mv /opt/local /opt/local_off ; sudo mv /usr/pkg /usr/pkg_off ; cd ~/Library/Application\\ Support/Guigna/Fink ; curl -L -O http://downloads.sourceforge.net/fink/fink-0.37.0.tar.gz ; tar -xvzf fink-0.37.0.tar.gz ; cd fink-0.37.0 ; sudo ./bootstrap ; /sw/bin/pathsetup.sh ; . /sw/bin/init.sh ; /sw/bin/fink selfupdate-rsync ; /sw/bin/fink index -f ; sudo mv /usr/local_off /usr/local ; sudo mv /opt/local_off /opt/local ; sudo mv /usr/pkg_off /usr/pkg"
  end
  def self.remove_cmd
    "sudo rm -rf /sw"
  end
  def verbosified(cmd)
    cmd.gsub(@cmd, @cmd + " -v")
  end
end
