# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'

class GScrape < GSource
  attr_accessor :page_number, :items_per_page
  def initialize(name = "", agent = nil)
    super(name, agent)
    @page_number = 1
  end
  def refresh
  end
end


class Freecode < GScrape
  
  def initialize(agent=nil)
    super("Freecode", agent)
    @homepage = "http://freecode.com/"
    @items_per_page = 25
    @cmd = "freecode"
  end
  def refresh
    projs = []
    url = "http://freecode.com/?page=#{page_number}"
    nodes = agent.nodes_for_url(url, xpath:"//div[contains(@class,\"release\")]")
    nodes.each { |node|
      name = node["h2/a"][-1].stringValue
      idx = name.rindex(" ")
      version = name[idx+1..-1]
      name = name[0...idx]
      id = node["h2/a"][-1].href.lastPathComponent
      # categories =
      moreinfo = node["h2//a[contains(@class,\"moreinfo\")]"]
      if moreinfo.size == 0
        homepage = @homepage
      else
        homepage = moreinfo[0]['@title']
        idx = homepage.rindex(" ")
        homepage = homepage[idx+1..-1]
        homepage = "http://" + homepage unless homepage.start_with? "http://"
      end
      tags = []
      taglist = node["ul/li"]
      taglist.each { |node| tags << node.stringValue }
      proj = GItem.new(name, version, self, :available)
      proj.id = id
      # proj.categories = categories
      proj.description = tags.join " "
      proj.homepage = homepage
      projs << proj
    }
    @items = projs
  end
  def home(item)
    item.homepage
  end
  def log(item)
    "http://freecode.com/projects/#{item.id}"
  end
end


class PkgsrcSE < GScrape
  
  def initialize(agent=nil)
    super("Pkgsrc.se", agent)
    @homepage = "http://pkgsrc.se/"
    @items_per_page = 15
    @cmd = "pkgsrc"
  end
  def refresh
    entries = []
    url = "http://pkgsrc.se/?page=#{page_number}"
    main_div = agent.nodes_for_url(url, xpath:"//div[@id=\"main\"]").first
    dates = main_div["h3"]
    names = main_div["b"][2..-1]
    comments = main_div["div"][2..-1]
    names.each_with_index do |node, i|
      id = node["a"].first.stringValue
      idx = id.rindex "/"
      name = id[idx+1..-1]
      category = id[0...idx]
      version = dates[i].stringValue
      idx = version.index " ("
      if !idx.nil?
        version = version[idx+2..-1]
        version = version[0...version.index(")")]
      else
        version = version.split.last
      end
      description = comments[i].stringValue
      description = description[0...description.index("\n")]
      description = description[description.index(": ")+2..-1]
      entry = GItem.new(name, version, self, :available)
      entry.id = id
      entry.description = description
      entry.categories = category
      entries << entry
    end
    @items = entries
  end
  def home(item)
    links = agent.nodes_for_url("http://pkgsrc.se/#{item.id}", xpath:"//div[@id=\"main\"]//a")
    links[2].href
  end
  
  def log(item)
    "http://pkgsrc.se/#{item.id}"
  end
end


class Debian < GScrape
  def initialize(agent=nil)
    super("Debian", agent)
    @homepage = "http://packages.debian.org/unstable/"
    @items_per_page = 100
    @cmd = "apt-get"
  end
  def refresh
    pkgs = []
    url = "http://news.gmane.org/group/gmane.linux.debian.devel.changes.unstable/last="
    nodes = agent.nodes_for_url(url, xpath:"//table[@class=\"threads\"]//table/tr")
    nodes.each do |node|
      link = node[".//a"].first.stringValue
      dummy, name, version = link.split
      # date =
      pkg = GItem.new(name, version, self, :available)
      # pkg.description
      pkgs << pkg
    end
    @items = pkgs
  end
  def home(item)
    page = log(item)
    links = agent.nodes_for_url(page, xpath:"//a[text()=\"Homepage\"]")
    if links.size > 0
      page = links.first.href
    end
    page
  end
  def log(item)
    "http://packages.debian.org/sid/#{item.name}"
  end
end


class MacUpdate < GScrape
  def initialize(agent=nil)
    super("MacUpdate", agent)
    @homepage = "http://www.macupdate.com"
    @items_per_page = 80
    @cmd = "macupdate"
  end
  def refresh
    apps = []
    url =  "https://www.macupdate.com/apps/page/#{page_number - 1}"
    nodes = agent.nodes_for_url(url, xpath:"//div[@class=\"appinfo\"]")
    nodes.each do |node|
      name = node["a"].first.stringValue
      version = ""
      # workaround for "this operation cannot be performed with encoding `UTF-8' because Apple's ICU does not support it"
      ascii_name = String.new(name).force_encoding("ASCII")
      if ascii_name.size != name.size
        idx = String.new(name).force_encoding("ASCII").rindex(" ") - (ascii_name.size - name.size)
      else
        idx = name.rindex(" ")
      end
      if !idx.nil?
        version = name[idx+1..-1]
        name = name[0...idx]
      end
      description = node["span"].first.stringValue[2..-1]
      id = node["a"].first.href.split("/")[3]
      app = GItem.new(name, version, self, :available)
      app.id = id
      # TODO app.categories = category
      app.description = description
      apps << app
    end
    @items = apps
  end
  def home(item)
    nodes = agent.nodes_for_url(log(item), xpath:"//a[@target=\"devsite\"]")
    "http://www.macupdate.com" + nodes[0].href.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
  end
  def log(item)
    "http://www.macupdate.com/app/mac/#{item.id}"
  end
end


class AppShopper < GScrape
  
  def initialize(agent=nil)
    super("AppShopper", agent)
    @homepage = "http://appshopper.com/mac/all/"
    @items_per_page = 20
    @cmd = "appstore"
  end
  
  def refresh
    apps = []
    url = "http://appshopper.com/mac/all/#{page_number}"
    nodes = agent.nodes_for_url(url, xpath:"//ul[@class=\"appdetails\"]/li")
    nodes.each do |node|
      name = node["h3/a"].first.stringValue
      version = node[".//dd"][2].stringValue
      id = node['@id'][4..-1]
      nick = node["a"].first.href.lastPathComponent
      id = id + " " + nick
      category = node["div[@class=\"category\"]"].first.stringValue[0..-2]
      type = node['@class']
      price = node[".//div[@class=\"price\"]"].first.children[0].stringValue
      cents = node[".//div[@class=\"price\"]"].first.children[1].stringValue
      if price == ""
        price = cents
      else
        price = price + "." + cents unless cents.start_with? "Buy"
      end
      # TODO: NSXML UTF8 encoding
      fixed_price = price.gsub("â‚¬", "€")
      app = GItem.new(name, version, self, :available)
      app.id = id
      app.categories = category
      app.description = type + " " + fixed_price
      apps << app
    end
    @items = apps
  end
  def home(item)
    main_div = agent.nodes_for_url("http://itunes.apple.com/app/id" + item.id.split.first, xpath:"//div[@id=\"main\"]").first
    links = main_div["//div[@class=\"app-links\"]/a"]
    screenshots_imgs = main_div["//div[contains(@class, \"screenshots\")]//img"]
    item.screenshots = screenshots_imgs.map {|img| img['@src']}.join(" ")
    homepage = links[0].href
    homepage = links[1].href if homepage == "http://"
    return homepage
  end
  def log(item)
    name = item.id.split[1]
    category = item.categories.gsub(" ", "-").downcase
    category = category.gsub("-&-", "-").downcase # fix Healthcare & Fitness
    "http://www.appshopper.com/mac/#{category}/#{name}"
  end
end


class AppShopperIOS < GScrape
  
  def initialize(agent=nil)
    super("AppShopper iOS", agent)
    @homepage = "http://appshopper.com/all/"
    @items_per_page = 20
    @cmd = "appstore"
  end
  
  def refresh
    apps = []
    url = "http://appshopper.com/all/#{page_number}"
    nodes = agent.nodes_for_url(url, xpath:"//ul[@class=\"appdetails\"]/li")
    nodes.each do |node|
      name = node["h3/a"].first.stringValue
      version = node[".//dd"][2].stringValue
      id = node['@id'][4..-1]
      nick = node["a"].first.href.lastPathComponent
      id = id + " " + nick
      category = node["div[@class=\"category\"]"].first.stringValue[0..-2]
      type = node['@class']
      price = node[".//div[@class=\"price\"]"].first.children[0].stringValue
      cents = node[".//div[@class=\"price\"]"].first.children[1].stringValue
      if price == ""
        price = cents
      else
        price = price + "." + cents unless cents.start_with? "Buy"
      end
      # TODO: NSXML UTF8 encoding
      fixed_price = price.gsub("â‚¬", "€")
      app = GItem.new(name, version, self, :available)
      app.id = id
      app.categories = category
      app.description = type + " " + fixed_price
      apps << app
    end
    @items = apps
  end
  def home(item)
    main_div = agent.nodes_for_url("http://itunes.apple.com/app/id" + item.id.split.first, xpath:"//div[@id=\"main\"]").first
    links = main_div["//div[@class=\"app-links\"]/a"]
    screenshots_imgs = main_div["//div[contains(@class, \"screenshots\")]//img"]
    item.screenshots = screenshots_imgs.map {|img| img['@src']}.join(" ")
    homepage = links[0].href
    homepage = links[1].href if homepage == "http://"
    return homepage
  end
  def log(item)
    name = item.id.split[1]
    category = item.categories.gsub(" ", "-").downcase
    category = category.gsub("-&-", "-").downcase # fix Healthcare & Fitness
    "http://www.appshopper.com/#{category}/#{name}"
  end
end


class PyPI < GScrape
  def initialize(agent=nil)
    super("PyPI", agent)
    @homepage = "http://pypi.python.org/pypi"
    @items_per_page = 40
    @cmd = "pip"
  end
  def refresh
    eggs = []
    nodes = agent.nodes_for_url(homepage, xpath:"//table[@class=\"list\"]//tr")[1..-2]
    nodes.each do |node|
      row_data = node["td"]
      date = row_data[0].stringValue
      link = row_data[1]["a"].first.href
      splits = link.split "/"
      name = splits[-2]
      version = splits[-1]
      description = row_data[2].stringValue
      egg = GItem.new(name, version, self, :available)
      egg.description = description
      eggs << egg
    end
    @items = eggs
  end
  def home(item)
    agent.nodes_for_url(self.log(item), xpath:"//ul[@class=\"nodot\"]/li/a").first.stringValue
    # if nil log(item)
  end
  def log(item)
    "#{homepage}/#{item.name}/#{item.version}"
  end
end


class RubyGems < GScrape
  def initialize(agent=nil)
    super("RubyGems", agent)
    @homepage = "http://rubygems.org/"
    @items_per_page = 25
    @cmd = "gem"
  end
  def refresh
    gems = []
    url = "http://m.rubygems.org/"
    nodes = agent.nodes_for_url(url, xpath:"//li")
    nodes.each do |node|
      name, version = node.stringValue.split
      spans = node[".//span"]
      date = spans[0].stringValue
      info = spans[1].stringValue
      gem = GItem.new(name, version, self, :available)
      gem.description = info
      gems << gem
    end
    @items = gems
  end
  def home(item) # TODO extract homepage
    page = log(item)
    links = agent.nodes_for_url(page, xpath:"//div[@class=\"links\"]/a")
    if links.size > 0
      links.each do |link|
        if link.stringValue == "Homepage"
          page = link.href
        end
      end
    end
    page
  end
  def log(item)
    "#{homepage}gems/#{item.name}"
  end
end


class CocoaPods < GScrape
  def initialize(agent=nil)
    super("CocoaPods", agent)
    @homepage = "http://www.cocoapods.org/"
    @items_per_page = 25
    @cmd = "pod"
    if `osascript -e 'application "Xcode" is running'` == 'true'
      @xcode = SBApplication.applicationWithBundleIdentifier "com.apple.dt.Xcode"
    end
  end
  def refresh
    pods = []
    url = "http://feeds.cocoapods.org/new-pods.rss"
    nodes = agent.nodes_for_url(url, xpath:"//item")
    nodes.each do |node|
      name = node["title"].first.stringValue
      description = node["description"].first.stringValue
      description = description[0...description.index("</p>")]
      description = description[3..-1] while description.start_with? "<p>"
      link = node["link"].first.stringValue
      date = node["pubDate"].first.stringValue[4,12]
      pod = GItem.new(name, "", self, :available)
      pod.description = description
      pod.homepage = link
      pods << pod
    end
    @items = pods
  end
  def home(item)
    item.homepage
  end
  def log(item)
    !item.nil? ? "http://github.com/CocoaPods/Specs/tree/master/#{item.name}" : "http://github.com/CocoaPods/Specs/commits"
  end
end

