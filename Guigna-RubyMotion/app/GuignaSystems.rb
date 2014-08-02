# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'

class GPackage < GItem
  
  attr_accessor :options, :marked_options, :repo
  
  def initialize(name, version, system, status)
    super
    self.system = system
  end
  
  def key
    @system.key_for_package self
  end
  
  def install_cmd
    self.system.install_cmd self
  end
  def uninstall_cmd
    self.system.uninstall_cmd self
  end
  def deactivate_cmd
    self.system.deactivate_cmd self
  end
  def upgrade_cmd
    self.system.upgrade_cmd self
  end
  def fetch_cmd
    self.system.fetch_cmd self
  end
  def clean_cmd
    self.system.clean_cmd self
  end
  
end


class GSystem < GSource
  
  class << self
  
    attr_accessor :prefix
    
    def list
      self.new.list
    end
    def installed
      self.new.installed
    end
    def outdated
      self.new.outdated
    end
    def inactive
      self.new.inactive
    end
  
  end
  
  attr_accessor :prefix, :index
  
  def initialize(name = "", agent = nil)
    super(name, agent)
    self.status = :on
    @prefix = self.class.prefix
    @index = {}
  end
  
  def list
    []
  end
  def installed
    []
  end
  def outdated
    []
  end
  def inactive
    []
  end

  def hidden?
    File.exist? "#{@prefix}_off"
  end
  def key_for_package(pkg)
    "#{pkg.name}-#{@name}"
  end
  def [](name)
    @index["#{name}-#{@name}"]
  end
  def []=(name, pkg)
    @index["#{name}-#{@name}"] = pkg
  end

  def categoriesList # TODO rubyfy
    cats = NSMutableSet.set
    @items.each do |item|
      cats.addObjectsFromArray(item.categories.split) if !item.categories.nil?
    end
    cats.allObjects.sortedArrayUsingSelector("compare:")
  end

  def available_commands #TODO
    [["help", "CMD help"],
    ["man", "man CMD"]]
  end
  
  def install_cmd(pkg)
    "#{cmd} install #{pkg.name}"
  end
  def uninstall_cmd(pkg)
    "#{cmd} uninstall #{pkg.name}"
  end
  def deactivate_cmd(pkg)
    "#{cmd} deactivate #{pkg.name}"
  end
  def upgrade_cmd(pkg)
    "#{cmd} upgrade #{pkg.name}"
  end
  def fetch_cmd(pkg)
    "#{cmd} fetch #{pkg.name}"
  end
  def clean_cmd(pkg)
    "#{cmd} clean #{pkg.name}"
  end
  def options(pkg)
    nil
  end
  def update_cmd
    nil
  end
  def hide_cmd
    nil
  end
  def unhide_cmd
    nil
  end

  def verbosified(cmd)
    cmd.gsub(@cmd, @cmd + " -d")
  end

end

