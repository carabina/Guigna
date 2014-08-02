# require 'GAdditions'
# require 'GuignaScrapes'
# require 'GAgent'

class GRepo < GScrape
  def update
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



