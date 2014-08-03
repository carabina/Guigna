# require 'GAdditions'
# require 'GuignaItems'
# require 'GAgent'
# require 'GuignaSystems'

class Homebrew < GSystem
  
  @prefix = '/usr/local'
  
  def initialize(agent=nil)
    super("Homebrew", agent)
    @homepage = "http://brew.sh/"
    @cmd = "#{@prefix}/bin/brew"
  end
  
  def casks?
    File.exist?("#{prefix}/bin/brew-cask.rb")
  end
  
  def list
    @index.clear
    @items.clear
    
    # /usr/bin/ruby -C /usr/local/Library/Homebrew -I. -e "require 'global'; require 'formula'; Formula.each {|f| puts \"#{f.name} #{f.pkg_version}\"}"
    
    formula_each = 'Formula.each {|f| puts \"#{f.name} #{f.pkg_version} #{f.bottle}\"}'
    output = `export HOME=~ ; export PATH=#{ENV["PATH"]} ; /usr/bin/ruby -C #{prefix}/Library/Homebrew -I. -e "require 'global'; require 'formula'; #{formula_each}"`
    output.split("\n").each do |line| # TODO @prefix
      name, version, bottle = line.split
      pkg = GPackage.new(name, version, self, :available)
      pkg.description = "Bottle" unless bottle.nil?
      @items << pkg
      self[name] = pkg
    end
    if self.agent.app_delegate.defaults['HomebrewMainTaps'] == true
      output = `export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd} search ""`
      output.split.each do |line| # TODO
        next if not line.include? "/"
        tokens = line.split "/"
        name = tokens.last
        repo = tokens[0...-1].join("/")
        pkg = GPackage.new(name, "", self, :available)
        pkg.categories = tokens[1]
        pkg.description = repo
        pkg.repo = repo
        @items << pkg
        self[name] = pkg
      end
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
    inactive = self.items.filteredArrayUsingPredicate(NSPredicate.predicateWithFormat("status == '#{:inactive}'"))
    @items.removeObjectsInArray(inactive)
    self.agent.app_delegate.all_packages.removeObjectsInArray(inactive) # TODO: ugly
    @items.each do |pkg|
      status = pkg.status
      pkg.installed = nil
      pkg.status = :available if status != :updated and status != :new
    end
    self.outdated # update status of outdated packages
    output = `export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd} list --versions`
    output.split("\n").each do |line|
      components = line.split
      name = components.shift
      version_count = components.size
      return [] if name == "Error"
      version = components[-1]
      pkg = self[name]
      latest_version = (pkg.nil? || pkg.version.nil?) ? nil : pkg.version.dup
      if version_count > 1
        for i in 0...version_count-1
          inactive_pkg = GPackage.new(name, latest_version, self, :inactive)
          inactive_pkg.installed = components[i]
          @items << inactive_pkg
          self.agent.app_delegate.all_packages << inactive_pkg # TODO: ugly
          pkgs << inactive_pkg
        end
      end
      if pkg.nil?
        pkg = GPackage.new(name, latest_version, self, :uptodate)
        self[name] = pkg
      else
        if pkg.status == :available
          pkg.status = :uptodate
        end
      end
      pkg.installed = version
      pkgs << pkg
    end
    return pkgs
  end
  
  def outdated
    if self.hidden?
      return @items.select {|pkg| pkg.status == :outdated}
    end
    pkgs = []
    return pkgs if self.mode == :online
    output = `export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd} outdated`
    output.split("\n").each do |line|
      name, version = line.split # TODO: strangely, output contains only name
      return pkgs if name == "Error:"
      pkg = self[name]
      latest_version = (pkg.nil? || pkg.version.nil?) ? nil : pkg.version.dup
      version = (pkg.nil? || pkg.installed.nil?) ? "..." : pkg.installed.dup
      if pkg.nil?
        pkg = GPackage.new(name, latest_version, self, :outdated)
        self[name] = pkg
      else
        pkg.status = :outdated
      end
      pkg.installed = version
      pkgs << pkg
    end
    pkgs
  end
  
  def inactive
    if self.hidden?
      return @items.select {|pkg| pkg.status == :inactive}
    end
    pkgs = []
    return pkgs if self.mode == :online
    return self.installed.select {|pkg| pkg.status == :inactive}
  end
  
  # TODO: review
  def info(pkg)
    if !self.hidden?
      `export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd} info #{pkg.name}`
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
        path = "Homebrew/homebrew/commits/master/Library/Formula"
      else
        user, category = pkg.repo.split "/"
        path = user + "/homebrew-" + category + "/commits/master"
        path << "/Formula" if user == "josegonzalez"
      end
      "http://github.com/#{path}/#{pkg.name}.rb"
    else
      "http://github.com/Homebrew/homebrew/commits"
    end
  end
  
  def contents(pkg)
    if !self.hidden?
      `export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd} list -v #{pkg.name}`
    else
      ""
    end
  end
  
  def cat(pkg)
    if !self.hidden?
      `export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd} cat #{pkg.name}`
    else
      formula_path = "#{@prefix}_off/Library/Formula/#{pkg.name}.rb"
      if File.exist?(formula_path)
        File.read(formula_path)
      else
        super
      end
    end
  end
  
  def deps(pkg)
    if !self.hidden?
      `export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd} deps -n #{pkg.name}`
    else
      "[Cannot compute the dependencies now]"
    end
  end
  
  def dependents(pkg)
    if !self.hidden?
      `export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd} uses --installed #{pkg.name}`
    else
      ""
    end
  end
  
  def options(pkg)
    options = nil
    output = `export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd} options #{pkg.name}`.split("\n")
    if output.size > 0
      output.select! {|line| line.start_with?("--")}
      options = output.join(" ").gsub("--", "")
    end
    options
  end
  
  def install_cmd(pkg)
    options = pkg.marked_options
    options = options.nil? ? "" : "--" + options.gsub(" ", " --")
    "#{cmd} install #{options} #{pkg.name}"
  end
  

  def uninstall_cmd(pkg)
    if pkg.status == :inactive
      return clean_cmd(pkg)
    else
      return "#{cmd} remove --force #{pkg.name}"  # TODO: manage --force flag
    end
  end
  def upgrade_cmd(pkg)
    "#{cmd} upgrade #{pkg.name}"
  end
  def clean_cmd(pkg)
    "#{cmd} cleanup --force #{pkg.name} &>/dev/null ; rm -f /Library/Caches/Homebrew/#{pkg.name}-#{pkg.version}*bottle*"
  end
  
  def update_cmd
    "export HOME=~ ; export PATH=#{ENV["PATH"]} ; #{cmd} update"
  end
  def hide_cmd
    "sudo mv #{prefix} #{prefix}_off"
  end
  def unhide_cmd
    "sudo mv #{prefix}_off #{prefix}"
  end
  
  def self.setup_cmd
    "ruby -e \"$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)\" ; /usr/local/bin/brew update"
  end
  def self.remove_cmd
    "cd /usr/local ; curl -L https://raw.github.com/gist/1173223 -o uninstall_homebrew.sh; sudo sh uninstall_homebrew.sh ; rm uninstall_homebrew.sh ; sudo rm -rf /Library/Caches/Homebrew; rm -rf /usr/local/.git"
  end

  def verbosified(cmd)
    tokens = cmd.split
    tokens.insert(2, "-v")
    tokens.join(" ")
  end

end
