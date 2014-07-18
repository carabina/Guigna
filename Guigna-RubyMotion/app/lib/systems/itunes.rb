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
      sep = ipa.rindex " "
      next if sep == nil
      filename = ipa[(ipa.rindex("/") + 1)...-4]
      version = ipa[sep+1...-4]
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
  def info(pkg)
    ipa = File.expand_path("~/Music/iTunes/iTunes Media/Mobile Applications/#{pkg.id}.ipa")
    metadata = load_plist `/usr/bin/unzip -p "#{ipa}" iTunesMetadata.plist`
    metadata.description
  end
  
  def contents(pkg)
    ipa = File.expand_path("~/Music/iTunes/iTunes Media/Mobile Applications/#{pkg.id}.ipa")
    `zipinfo -1 "#{ipa}"`
  end
  
end
