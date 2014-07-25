# require 'GAdditions'
# require 'GuignaScrapes'
# require 'GAgent'

class GRepo < GScrape
  def update
  end
end

class Rudix < GRepo
  
  def initialize(agent=nil)
    super("Rudix", agent)
    @homepage = "http://www.rudix.org/"
    @page_number = 1
    @items_per_page = 100
    @cmd = "rudix"
  end
  
  def refresh
    pkgs = []
    url = "http://rudix.org/download/2014/10.9/"
    links = agent.nodes_for_url(url, xpath:"//tbody//tr//a")
    decimalCharSet = NSCharacterSet.decimalDigitCharacterSet
    links.each do |link|
      name = link.stringValue
      next if name.start_with? 'Parent Dir' or name.include?("MANIFEST")
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
    "https://github.com/rudix-mac/rudix/commits/master/Ports/#{item.name}"
  end
end



class Native < GRepo
  
  def initialize(agent=nil)
    super("Native Installers", agent)
    @homepage = "http://github.com/gui-dos/Guigna/"
    @items_per_page = 250
    @cmd = "installer"
  end
  
  def refresh
    pkgs = []
    url = "https://docs.google.com/spreadsheet/ccc?key=0AryutUy3rKnHdHp3MFdabGh6aFVnYnpnUi1mY2E2N0E"
    nodes = agent.nodes_for_url(url, xpath:"//table[@id=\"tblMain\"]//tr")
    nodes.each do |node|
      next if !node.attributeForName("class").nil? # class is not empty ('rShim')
      columns = node["./td"]
      name = columns[1].stringValue
      version = columns[2].stringValue
      homepage = columns[4].stringValue
      url = columns[5].stringValue
      pkg = GItem.new(name, version, self, :available)
      pkg.homepage = homepage
      pkg.description = url
      pkg.url = url
      pkgs << pkg
    end
    @items = pkgs
  end
  
end



