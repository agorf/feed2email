require "open-uri"

module OpenURI
  class << self
    alias_method :old_redirectable?, :redirectable?
  end

  # Monkey-patch to allow redirection from "http" to "https" scheme
  def self.redirectable?(uri1, uri2)
    (uri1.scheme.downcase == "http" && uri2.scheme.downcase == "https") ||
      old_redirectable?(uri1, uri2)
  end
end
