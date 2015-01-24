require 'open-uri'

# Monkey patch to allow redirection from "http" scheme to "https"
def OpenURI.redirectable?(uri1, uri2)
  uri1.scheme.downcase == uri2.scheme.downcase ||
    (uri1.scheme =~ /\A(?:http|ftp)\z/i && uri2.scheme =~ /\A(?:https?|ftp)\z/i)
end
