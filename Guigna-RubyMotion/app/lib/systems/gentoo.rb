# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class Gentoo < GSystem # TODO
  
  @prefix = File.expand_path("~/Gentoo")
  
  def initialize(agent=nil)
    super("Gentoo", agent)
    @homepage = "http://www.gentoo.org/proj/en/gentoo-alt/prefix/"
    @cmd = @prefix + "/bin/emerge"
  end
  
  def log(pkg)
    "http://packages.gentoo.org/arch/x64-macos?arches=all"
  end
  
  def self.setup_cmd
    "sudo mv /usr/local /usr/local_off ; sudo mv /opt/local /opt/local_off ; sudo mv /sw /sw_off ; cd ~/Library/Application\\ Support/Guigna/Gentoo ; curl -L http://overlays.gentoo.org/proj/alt/browser/trunk/prefix-overlay/scripts/bootstrap-prefix.sh?format=txt -o bootstrap-prefix.sh ; chmod 755 bootstrap-prefix.sh ; ./bootstrap-prefix.sh ; sudo mv /usr/local_off /usr/local ; sudo mv /opt/local_off /opt/local ; sudo mv /sw_off /sw"
  end

end
