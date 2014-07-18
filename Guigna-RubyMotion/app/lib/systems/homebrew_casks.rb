# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class HomebrewCasks < GSystem
  
  @prefix = '/usr/local'
  
  def initialize(agent=nil)
    super("Homebrew Casks", agent)
    @homepage = "http://caskroom.io"
    @cmd = "#{@prefix}/bin/brew cask"
  end
  
  def list
    @index.clear
    @items.clear
    output = `grep "version '" -r #{prefix}/Library/Taps/caskroom/homebrew-cask/Casks`
    output.split("\n").each do |line|
      components = line.split(' ')
      name = components[0].lastPathComponent[0..-5]
      version = components.last[1..-2]
      pkg = GPackage.new(name, version, self, :available)
      # avoid duplicate entries (i.e. aquamacs, opensesame) 
      if !self[name].nil?
        prev_pkg = @items.delete self[name]
        pkg = prev_pkg if prev_pkg.version > version
      end
      @items << pkg
      self[name] = pkg
    end
    self.installed # update index status
    @items
  end
  
  def installed
    if self.hidden?
      return @items.select {|pkg| pkg.status != :available}
    end
    pkgs = []
    return pkgs if self.mode == :online
    # TODO: remove inactive packages from items and allPackages
    @items.each do |pkg|
      status = pkg.status
      pkg.installed = nil
      pkg.status = :available if status != :updated and status != :new
    end
    output = `export HOME=~ ; export PATH=#{ENV["PATH"]} ; export PATH=#{prefix}/bin:$PATH ; #{cmd} list 2>/dev/null`
    output.split("\n").each do |name|
      return [] if name == "Error"
      version = `ls /opt/homebrew-cask/Caskroom/#{name}`.chomp
      # TODO: manage multiple versions
      version.gsub!("\n", ", ")
      pkg = self[name]
      latest_version = (pkg.nil? || pkg.version.nil? ) ? nil : pkg.version.dup
      if pkg.nil?
        pkg = GPackage.new(name, latest_version, self, :uptodate)
        self[name] = pkg
      else
        if pkg.status == :available
          pkg.status = :uptodate
        end
      end
      pkg.installed = version # TODO
      if !latest_version.nil? && !version.end_with?(latest_version)
        pkg.status = :outdated
      end  
      pkgs << pkg
    end
    return pkgs
  end

  def outdated
    pkgs = self.installed.select {|pkg| pkg.status == :outdated}
  end

  def info(pkg)
    if !self.hidden?
      `export HOME=~ ; export PATH=#{ENV["PATH"]} ; export PATH=#{prefix}/bin:$PATH ; #{cmd} info #{pkg.name}`
    else
      super
    end
  end
  
  def home(pkg)
    if self.hidden?
      cat(pkg).split("\n").each do |line|
        loc = line.index('homepage')
        if !loc.nil?
          homepage = line[loc+8..-1].strip
          if homepage.include?('http')
            return homepage.tr('\'"', '')
          end
        end
      end
    elsif !self.hidden? && pkg.repo.nil?
      return `export HOME=~ ; export PATH=#{ENV["PATH"]} ; export PATH=#{prefix}/bin:$PATH ; #{cmd} info #{pkg.name}`.split("\n")[1]
    end
    log(pkg)
  end
  
  def log(pkg)
    if !pkg.nil?
      if pkg.repo.nil?
        path = "caskroom/homebrew-cask/commits/master/Casks"
        # else
        # user, category = pkg.repo.split "/"
        # path = user + "/homebrew-" + category + "/commits/master"
      end
      "http://github.com/#{path}/#{pkg.name}.rb"
    else
      "http://github.com/caskroom/homebrew-cask/commits"
    end
  end
  
  def contents(pkg)
    if !self.hidden?
      `export HOME=~ ; export PATH=#{ENV["PATH"]} ; export PATH=#{prefix}/bin:$PATH ; #{cmd} list #{pkg.name}`
    else
      ""
    end
  end
  
  def cat(pkg)
    if !self.hidden?
      `export HOME=~ ; export PATH=#{ENV["PATH"]} ; export PATH=#{prefix}/bin:$PATH ; #{cmd} cat #{pkg.name}`
    else
      File.read("#{prefix}_off/Library/Taps/caskroom/homebrew-cask/Casks/#{pkg.name}.rb")
    end
  end
  
  def install_cmd(pkg)
    options = pkg.marked_options
    options = options.nil? ? "" : "--" + options.gsub(" ", " --")
    "#{cmd} install #{options} #{pkg.name}"
  end
  def uninstall_cmd(pkg)
    "#{cmd} uninstall #{pkg.name}"
  end
  # FIXME: not possible currently
  def upgrade_cmd(pkg)
    "#{cmd} uninstall #{pkg.name} ; #{cmd} install #{pkg.name}"
  end
  def clean_cmd(pkg)
    "#{cmd} cleanup --force #{pkg.name} &>/dev/null"
  end
  
  def hide_cmd
    "sudo mv #{prefix} #{prefix}_off"
  end
  def unhide_cmd
    "sudo mv #{prefix}_off #{prefix}"
  end
  
  def self.setup_cmd
    "#{prefix}/bin/brew install caskroom/cask/brew-cask ; #{prefix}/bin/brew cask list"
  end
  def self.remove_cmd
    "#{prefix}/bin/brew untap caskroom/cask"
  end

  def verbosified(cmd)
    tokens = cmd.split
    tokens.insert(2, "-v")
    tokens.join(" ")
  end
end
