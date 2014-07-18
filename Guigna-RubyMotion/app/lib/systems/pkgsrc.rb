# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class Pkgsrc < GSystem
  
  @prefix = '/usr/pkg'
  
  def initialize(agent=nil)
    super("pkgsrc", agent)
    @homepage = "http://www.pkgsrc.org"
    @cmd = "#{@prefix}/sbin/pkg_info"
  end
  
  # include category for managing duplicates of xp, binutils, fuse, p5-Net-CUPS
  def key_for_package(pkg)
    if !pkg.id.nil?
      "#{pkg.id}-#{@name}"
    else
      return "#{pkg.categories.split.first}/#{pkg.name}-#{@name}"
    end
  end
  
  def list
    @index.clear
    @items.clear
    index_path = File.expand_path("~/Library/Application Support/Guigna/pkgsrc/INDEX")
    if File.exist? index_path
      lines = NSString.stringWithContentsOfFile(index_path, encoding:NSUTF8StringEncoding, error:nil).split("\n")
      lines.each do |line|
        components = line.split "|"
        name = components.first
        sep = name.rindex "-"
        next if sep.nil?
        version = name[sep+1..-1]
        # name = [name substringToIndex:sep]
        id = components[1]
        sep = id.rindex "/"
        name = id[sep+1..-1]
        description = components[3]
        category = components[6]
        homepage = components[11]
        pkg = GPackage.new(name, version, self, :available)
        pkg.id = id
        pkg.categories = category
        pkg.description = description
        pkg.homepage = homepage
        @items << pkg
        self[id] = pkg
      end
    else
      nodes = agent.nodes_for_url("http://ftp.netbsd.org/pub/pkgsrc/current/pkgsrc/README-all.html", xpath:"//tr")
      nodes.each do |node|
        row_data = node["td"]
        next if row_data.size == 0
        name = row_data.first.stringValue
        sep = name.rindex("-")
        next if !sep
        version = name[sep+1..-3]
        name = name[0...sep]
        category = row_data[1].stringValue
        category = category[1..-3]
        description = row_data[2].stringValue
        sep = description.rindex("  ")
        description = description[0...sep] if sep
        pkg = GPackage.new(name, version, self, :available)
        pkg.categories = category
        pkg.description = description
        id = "#{category}/#{name}"
        pkg.id = id
        @items << pkg
        self[id] = pkg
      end
    end
    self.installed
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
    # self.outdated # index outdated ports
    output = `#{@cmd}`.split("\n")
    ids = `#{cmd} -Q PKGPATH -a`.split("\n")
    status = nil
    i = 0
    output.each do |line|
      sep = line.index " "
      name = line[0...sep]
      description = line[sep+1..-1].strip
      sep = name.rindex "-"
      version = name[sep+1..-1]
      # name = [name substringToIndex:sep]
      id = ids[i]
      sep = id.index "/"
      name = id[sep+1..-1]
      status = :uptodate
      pkg = self[id]
      latest_version = (pkg.nil? || pkg.version.nil? ) ? nil : pkg.version.dup
      if pkg.nil?
        pkg = GPackage.new(name, latest_version, self, status)
        self[id] = pkg
      else
        pkg.status = status if pkg.status == :available
      end
      pkg.installed = version
      pkg.description = description
      pkg.id = id
      pkgs << pkg
      i += 1
    end
    pkgs
  end
  def outdated # TODO
    pkgs = []
    pkgs
  end
  
  # TODO: pkg_info -d
  # TODO: pkg_info -B PKGPATH=misc/figlet
  
  def info(pkg)
    if self.hidden?
      return super
    end
    if self.mode != :online && pkg.status != :available
      return `#{cmd} #{pkg.name}`
    else
      if !pkg.id.nil?
        return NSString.stringWithContentsOfURL(NSURL.URLWithString("http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/#{pkg.id}/DESCR"), encoding:NSUTF8StringEncoding, error:nil)
      else # TODO lowercase (i.e. Hermes -> hermes)
        return NSString.stringWithContentsOfURL(NSURL.URLWithString("http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/#{pkg.categories}/#{pkg.name}/DESCR"), encoding:NSUTF8StringEncoding, error:nil)
      end
    end
  end
  def home(pkg)
    if !pkg.homepage.nil? # already available from INDEX
      return pkg.homepage
    else
      links = self.agent.nodes_for_url("http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/#{pkg.categories}/#{pkg.name}/README.html", xpath:"//p/a")
      return links[2].href
    end
  end
  def log(pkg)
    if !pkg.nil?
      if pkg.id != nil
        return "http://cvsweb.NetBSD.org/bsdweb.cgi/pkgsrc/#{pkg.id}/"
      else
        return "http://cvsweb.NetBSD.org/bsdweb.cgi/pkgsrc/#{pkg.categories}/#{pkg.name}/"
      end
    else
      return "http://www.netbsd.org/changes/pkg-changes.html"
    end
  end
  def contents(pkg)
    if pkg.status != :available
      return `#{@cmd} -L #{pkg.name}`.split("Files:\n")[1]
    else
      if !pkg.id.nil?
        return NSString.stringWithContentsOfURL(NSURL.URLWithString("http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/#{pkg.id}/PLIST", encoding:NSUTF8StringEncoding, error:nil))
      else
        return NSString.stringWithContentsOfURL(NSURL.URLWithString("http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/#{pkg.categories}/#{pkg.name}/PLIST", encoding:NSUTF8StringEncoding, error:nil))
      end
    end
  end
  
  def cat(pkg)
    if pkg.status != :available # TODO: rubyfy
      filtered = @items.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("name == '#{pkg.name}'"))
      pkg.id = filtered.first.id
    end
    if !pkg.id.nil?
      return NSString.stringWithContentsOfURL(NSURL.URLWithString("http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/#{pkg.id}/Makefile", encoding:NSUTF8StringEncoding, error:nil))
    else
      return NSString.stringWithContentsOfURL(NSURL.URLWithString("http://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc/#{pkg.categories}/#{pkg.name}/Makefile", encoding:NSUTF8StringEncoding, error:nil))
    end
  end
  
  # TODO: Deps: pkg_info -n -r, scrape site, parse Index
  # REVIEW deps, dependents
  
  def deps(pkg) # FIXME: "*** PACKAGE MAY NOT BE DELETED *** "
    if pkg.status != :available
      components = `#{@cmd} -n #{pkg.name}`.split("Requires:\n")
      if components.size > 1
        return components[1].strip
      else
        return "[No depends]"
      end
    else
      if File.exist?(File.expand_path("~/Library/Application Support/Guigna/pkgsrc/INDEX"))
        # TODO: parse INDEX
      end
      "[Not available]"
    end
  end
  
  def dependents(pkg)
    if pkg.status != :available
      components = `#{@cmd} -r #{pkg.name}`.split("required by list:\n")
      if components.size > 1
        return components[1].strip
      else
        return "[No dependents]"
      end
    else
      return "[Not available]"
    end
  end
  
  def install_cmd(pkg)
    if !pkg.id.nil?
      return "cd /usr/pkgsrc/#{pkg.id} ; sudo /usr/pkg/bin/bmake install clean clean-depends"
    else
      return "cd /usr/pkgsrc/#{pkg.categories}/#{pkg.name} ; sudo /usr/pkg/bin/bmake install clean clean-depends"
    end
  end
  def uninstall_cmd(pkg)
    "sudo #{@prefix}/sbin/pkg_delete #{pkg.name}"
  end
  def clean_cmd(pkg)
    if !pkg.id.nil?
      return "cd /usr/pkgsrc/#{pkg.id} ; sudo /usr/pkg/bin/bmake clean clean-depends"
    else
      return "cd /usr/pkgsrc/#{pkg.categories}/#{pkg.name} ; sudo /usr/pkg/bin/bmake clean clean-depends"
    end
  end
  
  def update_cmd
    if self.mode == :online || self.agent.app_delegate.defaults['pkgsrcCVS'] == false
      nil
    else
      "sudo cd; cd /usr/pkgsrc ; sudo cvs update -dP"
    end
  end
  def hide_cmd
    "sudo mv #{prefix} #{prefix}_off"
  end
  def unhide_cmd
    "sudo mv #{prefix}_off #{prefix}"
  end
  
  def self.setup_cmd
    "sudo mv /usr/local /usr/local_off ; sudo mv /opt/local /opt/local_off ; sudo mv /sw /sw_off ; cd ~/Library/Application\\ Support/Guigna/pkgsrc ; curl -L -O ftp://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc.tar.gz ; sudo tar -xvzf pkgsrc.tar.gz -C /usr; cd /usr/pkgsrc/bootstrap ; sudo ./bootstrap --compiler clang ; sudo mv /usr/local_off /usr/local ; sudo mv /opt/local_off /opt/local ; sudo mv /sw_off /sw"
  end
  def self.remove_cmd
    "sudo rm -r /usr/pkg ; sudo rm -r /usr/pkgsrc ; sudo rm -r /var/db/pkg"
  end
end
