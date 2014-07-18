# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class FreeBSD < GSystem
  
  @prefix = ""
  
  def initialize(agent=nil)
    super("FreeBSD", agent)
    @homepage = "http://www.freebsd.org/ports/"
    @cmd = "freebsd"
  end
  
  def list
    @index.clear
    @items.clear
    index_path = File.expand_path("~/Library/Application Support/Guigna/FreeBSD/INDEX")
    if File.exist? index_path
      lines = NSString.stringWithContentsOfFile(index_path, encoding:NSUTF8StringEncoding, error:nil).split("\n")
      lines.each do |line|
        components = line.split "|"
        name = components.first
        sep = name.rindex "-"
        next if sep.nil?
        version = name[sep+1..-1]
        name = name[0...sep]
        description = components[3]
        category = components[6]
        homepage = components[9]
        pkg = GPackage.new(name, version, self, :available)
        pkg.categories = category
        pkg.description = description
        pkg.homepage = homepage
        @items << pkg
        # self[id] = pkg
      end
    else
      root = agent.nodes_for_url("http://www.freebsd.org/ports/master-index.html", xpath:"/*")[0]
      names = root["//p/strong/a"]
      descriptions = root["//p/em"]
      i = 0
      names.each do |node|
        name = node.stringValue
        sep = name.rindex("-")
        version = name[sep+1..-1]
        name = name[0...sep]
        category = node.href
        description = descriptions[i].stringValue
        category = category[0...category.index('.html')]
        pkg = GPackage.new(name, version, self, :available)
        pkg.categories = category
        pkg.description = description
        @items << pkg
        # self[id] = pkg
        i += 1
      end
    end
    @items
  end
  
  def info(pkg) # TODO: Offline mode
    category = pkg.categories.split.first # use first category when using INDEX
    nodes = agent.nodes_for_url("http://www.FreeBSD.org/cgi/url.cgi?ports/#{category}/#{pkg.name}/pkg-descr", xpath:"//pre")
    if nodes.size == 0
      nodes = agent.nodes_for_url("http://www.FreeBSD.org/cgi/url.cgi?ports/#{category}/#{pkg.name.downcase}/pkg-descr", xpath:"//pre")
    end
    if nodes.size == 0
      return "[Info not reachable]"
    else
      return nodes[0].stringValue
    end
  end
  
  def home(pkg)
    if !pkg.homepage.nil? # already available from INDEX
      return pkg.homepage
    else
      category = pkg.categories.split.first
      nodes = agent.nodes_for_url("http://www.FreeBSD.org/cgi/url.cgi?ports/#{category}/#{pkg.name}/pkg-descr", xpath:"//pre/a")
      if nodes.size == 0
        nodes = agent.nodes_for_url("http://www.FreeBSD.org/cgi/url.cgi?ports/#{category}/#{pkg.name.downcase}/pkg-descr", xpath:"//pre/a")
      end
      return nodes.size == 0 ? @homepage : nodes[0].stringValue
    end
  end
  
  def log(pkg)
    if !pkg.nil?
      "http://www.freshports.org/#{pkg.categories.split.first}/#{pkg.name}"
    else
      "http://www.freshports.org"
    end
  end
  
  def contents(pkg)
    category = pkg.categories.split.first
    pkg_name = pkg.name
    pkg_plist = NSString.stringWithContentsOfURL(NSURL.URLWithString("http://svnweb.freebsd.org/ports/head/#{category}/#{pkg_name}/pkg-plist?view=co"), encoding:NSUTF8StringEncoding, error:nil)
    if pkg_plist.start_with? "<!DOCTYPE" # 404 File Not Found
      pkg_name = pkg_name.downcase
      pkg_plist = NSString.stringWithContentsOfURL(NSURL.URLWithString("http://svnweb.freebsd.org/ports/head/#{category}/#{pkg_name}/pkg-plist?view=co"), encoding:NSUTF8StringEncoding, error:nil)
    end
    pkg_plist = "" if pkg_plist.start_with? "<!DOCTYPE"
    return pkg_plist
  end
  
  def cat(pkg)
    category = pkg.categories.split.first
    pkg_name = pkg.name
    makefile = NSString.stringWithContentsOfURL(NSURL.URLWithString("http://svnweb.freebsd.org/ports/head/#{category}/#{pkg_name}/Makefile?view=co"), encoding:NSUTF8StringEncoding, error:nil)
    if makefile.start_with? "<!DOCTYPE" # 404 File Not Found
      pkg_name = pkg_name.downcase
      makefile = NSString.stringWithContentsOfURL(NSURL.URLWithString("http://svnweb.freebsd.org/ports/head/#{category}/#{pkg_name}/Makefile?view=co"), encoding:NSUTF8StringEncoding, error:nil)
    end
    makefile = '[Makefile not reachable]' if makefile.start_with? "<!DOCTYPE"
    return makefile
  end

end
