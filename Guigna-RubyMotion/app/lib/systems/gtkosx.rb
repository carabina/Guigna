# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class GtkOSX < GSystem # TODO
  
  @prefix = File.expand_path("~/.local")
  
  def initialize(agent=nil)
    super("Gtk-OSX", agent)
    @homepage = "http://live.gnome.org/GTK%2B/OSX"
    @cmd = "#{@prefix}/bin/jhbuild"
  end
  def log(pkg)
    "http://git.gnome.org/browse/gtk-osx/"
  end
  def self.setup_cmd
    "sudo mv /usr/local /usr/local_off ; sudo mv /opt/local /opt/local_off ; sudo mv /sw /sw_off ; cd ~/Library/Application\\ Support/Guigna/ ; curl -L -O http://git.gnome.org/browse/gtk-osx/plain/gtk-osx-build-setup.sh ; sh gtk-osx-build-setup.sh ; ~/.local/bin/jhbuild bootstrap ; ~/.local/bin/jhbuild build meta-gtk-osx-bootstrap ; ~/.local/bin/jhbuild build meta-gtk-osx-core ; ~/.local/bin/jhbuild shell ; sudo mv /usr/local_off /usr/local ; sudo mv /opt/local_off /opt/local ; sudo mv /sw_off /sw"
  end
  def self.remove_cmd
    "rm -rf ~/gtk ; rm -rf ~/.local ; rm ~/.jhbuildrc*"
  end
end
