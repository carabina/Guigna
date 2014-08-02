module G
  def self.os_version
    NSProcessInfo.processInfo.operatingSystemVersionString.split[1]
  end
end
