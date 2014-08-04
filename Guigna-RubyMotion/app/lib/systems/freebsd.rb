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
        idx = name.rindex "-"
        next if idx.nil?
        version = name[idx+1..-1]
        name = name[0...idx]
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
        idx = name.rindex("-")
        version = name[idx+1..-1]
        name = name[0...idx]
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
    category = pkg.categories.split.first
    pkg_name = pkg.name
    pkg_descr = NSString.stringWithContentsOfURL(NSURL.URLWithString("http://svnweb.freebsd.org/ports/head/#{category}/#{pkg_name}/pkg-descr?view=co"), encoding:NSUTF8StringEncoding, error:nil)
    if pkg_descr.start_with? "<!DOCTYPE" # 404 File Not Found
      pkg_name = pkg_name.downcase
      pkg_descr = NSString.stringWithContentsOfURL(NSURL.URLWithString("http://svnweb.freebsd.org/ports/head/#{category}/#{pkg_name}/pkg-descr?view=co"), encoding:NSUTF8StringEncoding, error:nil)
    end
    pkg_descr = "[Info not reachable]" if pkg_descr.start_with? "<!DOCTYPE"
    return pkg_descr
  end
  
  def home(pkg)
    if !pkg.homepage.nil? # already available from INDEX
      return pkg.homepage
    else
      pkg_descr = info(pkg)
      if pkg_descr != "[Info not reachable]"
        pkg_descr.split("\n").reverse_each do |line|
          idx = line.index("WWW:")
          if idx != nil
            return line[4..-1].strip
          end
        end
      end
    end
    log(pkg)
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
  
  # TODO:deps => parse requirements:
  # http://www.FreeBSD.org/cgi/ports.cgi?query=%5E' + '%@-%@' item.name-item.version
  
end
