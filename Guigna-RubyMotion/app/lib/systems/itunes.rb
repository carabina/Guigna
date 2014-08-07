# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class ITunes < GSystem
  @prefix = ""
  
  def initialize(agent=nil)
    super("iTunes", agent)
    @homepage = "https://itunes.apple.com/genre/ios/id36?mt=8"
    @cmd = "/Applications/iTunes.app/Contents/MacOS/iTunes"
  end
  def list
    @index.clear
    @items.clear
    @items = self.installed
    @items
  end
  def installed
    pkgs = []
    ipas = Dir[File.expand_path("~/Music/iTunes/iTunes Media/Mobile Applications/*")]
    ipas.each do |ipa|
      idx = ipa.rangeOfString(" ", options:NSBackwardsSearch).location
      # workaround for "this operation cannot be performed with encoding `UTF-8' because Apple's ICU does not support it"
      next if idx == NSNotFound
      filename = File.basename(ipa)[0...-4]
      version = ipa[idx+1...-4]
      metadata = load_plist `/usr/bin/unzip -p "#{ipa}" iTunesMetadata.plist`
      name = metadata["itemName"]
      pkg = GPackage.new(name, "", self, :installed)
      pkg.id = filename
      pkg.installed = version
      pkg.categories = metadata["genre"]
      pkgs << pkg
    end
    pkgs
  end
  def home(pkg)
    homepage = self.homepage
    ipa = File.expand_path("~/Music/iTunes/iTunes Media/Mobile Applications/#{pkg.id}.ipa")
    metadata = load_plist `/usr/bin/unzip -p "#{ipa}" iTunesMetadata.plist`
    item_id = metadata["itemId"]
    main_div = agent.nodes_for_url("http://itunes.apple.com/app/id#{item_id}", xpath:"//div[@id=\"main\"]").first
    links = main_div["//div[@class=\"app-links\"]/a"]
    screenshots_imgs = main_div["//div[contains(@class, \"screenshots\")]//img"]
    pkg.screenshots = screenshots_imgs.map {|img| img['@src']}.join(" ")
    homepage = links[0].href
    homepage = links[1].href if homepage == "http://"
    return homepage
  end
  def log(pkg)
    if pkg.nil?
      return @homepage
    else
      ipa = File.expand_path("~/Music/iTunes/iTunes Media/Mobile Applications/#{pkg.id}.ipa")
      metadata = load_plist `/usr/bin/unzip -p "#{ipa}" iTunesMetadata.plist`
      item_id = metadata["itemId"]
      return "http://itunes.apple.com/app/id#{item_id}"
    end
  end
  def info(pkg)
    self.cat(pkg)
  end
  def contents(pkg)
    ipa = File.expand_path("~/Music/iTunes/iTunes Media/Mobile Applications/#{pkg.id}.ipa")
    `zipinfo -1 "#{ipa}"`
  end
  def cat(pkg)
    ipa = File.expand_path("~/Music/iTunes/iTunes Media/Mobile Applications/#{pkg.id}.ipa")
    metadata = load_plist `/usr/bin/unzip -p "#{ipa}" iTunesMetadata.plist`
    metadata.description
  end
  
end
