# require 'GAdditions'
# require 'GAgent'

class GItem
  attr_accessor :name, :version, :installed, :categories
  attr_accessor :homepage, :screenshots, :url, :date, :license, :id
  attr_accessor :source, :status, :mark

  # RubyMotion requires explicit accessors for 'description' and 'system'.
  
  def description=(str)
    @description = str
  end
  
  def description
    @description
  end
  
  def system=(sys)
    @system = sys
  end
  
  def system
    @system
  end
    
  def initialize(name, version, source, status)
    @name = name
    @version = version
    @source = source
    @status = status
  end
  
  def to_s
    self.version.to_s == "" ? "#{name}" : "#{@name}-#{@version}"
  end
  
  def status_order
    case @status
    when :broken    then 6
    when :new       then 5
    when :updated   then 4
    when :outdated  then 3
    when :uptodate  then 2
    when :inactive  then 1
    when :available then 0
    end
  end
  
  def info
    self.source.info self
  end
  
  def home
    self.source.home self
  end

  def log
    self.source.log self
  end

  def contents
    self.source.contents self
  end
  
  def cat
    self.source.cat self
  end

  def deps
    self.source.deps self
  end
  
  def dependents
    self.source.dependents self
  end

end


class GSource
  attr_accessor :name, :categories, :items, :homepage, :agent, :cmd
  
  def initialize(name = "", agent = nil)
    @name = name
    @items = []
    @agent = agent.nil? ? GAgent.new : agent # Allow calling from scripts
    @status = 1
  end
  
  # Compatibility wirh Objective-c enums:
  def status
    case @status
    when 0 then :off
    when 1 then :on
    end
  end
  
  def status=(value)
    case value
    when :on  then @status = 1
    when :off then @status = 0
    end
  end
  
  def mode
    case @mode
    when 0 then :offline
    when 1 then :online
    end
  end
  
  def mode=(value)
    case value
    when :online  then @mode = 1
    when :offline then @mode = 0
    end
  end
  
  def info(item)
    "#{item.name} - #{item.version}\n#{self.home(item)}"
  end
  
  def home(item)
    (!item.nil? && !item.homepage.nil?) ? item.homepage : "#{@homepage}"
  end
  
  def log(item)
    self.home(item)
  end
  def contents(item)
    ""
  end
  def cat(item)
    "[Not available]"
  end
  def deps(item)
    ""
  end
  def dependents(item)
    ""
  end
end


class GStatusTransformer < NSValueTransformer
  
  def self.transformedValueClass
    NSImage.class
  end
  
  def self.allowsReverseTransformation
    return false
  end
  
  def transformedValue(status)
    case status
    when :inactive
      NSImage.imageNamed(NSImageNameStatusNone)
    when :uptodate
      NSImage.imageNamed(NSImageNameStatusAvailable)
    when :outdated
      NSImage.imageNamed(NSImageNameStatusPartiallyAvailable)
    when :updated
      NSImage.imageNamed("status-updated.tiff")
    when :new
      NSImage.imageNamed("status-new.tiff")
    when :broken
      NSImage.imageNamed(NSImageNameStatusUnavailable)
    else nil
    end
  end
end


class GSourceTransformer < NSValueTransformer
  
  def self.transformedValueClass
    NSImage.class
  end
  
  def self.allowsReverseTransformation
    return false
  end
  
  def transformedValue(source)
    return if source.nil?
    case source.name
    when "MacPorts"
      NSImage.imageNamed("system-macports.tiff")
    when "Homebrew"
      NSImage.imageNamed("system-homebrew.tiff")
    when "Homebrew Casks"
      NSImage.imageNamed("system-homebrewcasks.tiff")
    when "Mac OS X"
      NSImage.imageNamed("system-macosx.tiff")
    when "iTunes"
      NSImage.imageNamed("system-itunes.tiff")
    when "Fink"
      NSImage.imageNamed("system-fink.tiff")
    when "pkgsrc"
      NSImage.imageNamed("system-pkgsrc.tiff")
    when "FreeBSD"
      NSImage.imageNamed("source-freebsd.tiff")
    when "Rudix"
      NSImage.imageNamed("system-rudix.tiff")
    when "Native Installers"
      NSImage.imageNamed("source-native.tiff")
    when "PyPI"
      NSImage.imageNamed("source-pypi.tiff")
    when "RubyGems"
      NSImage.imageNamed("source-rubygems.tiff")
    when "CocoaPods"
      NSImage.imageNamed("source-cocoapods.tiff")
    when "Debian"
      NSImage.imageNamed("source-debian.tiff")
    when "Freecode"
      NSImage.imageNamed("source-freecode.tiff")
    when "Pkgsrc.se"
      NSImage.imageNamed("source-pkgsrc.se.tiff")
    when "AppShopper"
      NSImage.imageNamed("source-appshopper.tiff")
    when "AppShopper iOS"
      NSImage.imageNamed("source-appshopper.tiff")
    when "MacUpdate"
      NSImage.imageNamed("source-macupdate.tiff")
    when "installed"
      NSImage.imageNamed(NSImageNameStatusAvailable)
    when "outdated"
      NSImage.imageNamed(NSImageNameStatusPartiallyAvailable)
    when "inactive"
      NSImage.imageNamed(NSImageNameStatusNone)
    when /^marked/
      NSImage.imageNamed("status-marked.tiff")
    when /^updated/
      NSImage.imageNamed("status-updated.tiff")
    when /^new/
      NSImage.imageNamed("status-new.tiff")
      
    else nil
    end
  end
  
end


class GMarkTransformer < NSValueTransformer
  
  def self.transformedValueClass
    NSImage.class
  end
  
  def self.allowsReverseTransformation
    return false
  end
  
  def transformedValue(mark)
    case mark
    when :install
      NSImage.imageNamed(NSImageNameAddTemplate)
    when :uninstall
      NSImage.imageNamed(NSImageNameRemoveTemplate)
    when :deactivate
      NSImage.imageNamed(NSImageNameStopProgressTemplate)
    when :upgrade
      NSImage.imageNamed(NSImageNameRefreshTemplate)
    when :fetch
      NSImage.imageNamed("source-native.tiff")
    when :clean
      NSImage.imageNamed(NSImageNameActionTemplate)
      
    else nil
    end
  end
  
end
