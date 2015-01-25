require 'cgi'
require 'reverse_markdown'
require 'sanitize'

class Hash
  def slice(*keys)
    Hash[values_at(*keys).each_with_index.map {|v, i| [keys[i], v] }]
  end
end

class Numeric
  def megabytes
    self * 1024 * 2014
  end
end

class String
  def escape_html
    CGI.escapeHTML(self)
  end

  def numeric?
    to_i.to_s == self
  end

  def pluralize(count, plural = self + 's')
    "#{count} #{count == 1 ? self : plural}"
  end

  def strip_html
    CGI.unescapeHTML(Sanitize.clean(self))
  end

  def to_markdown
    ReverseMarkdown.convert(self, unknown_tags: :drop)
  end
end

class Time
  def past?
    self < Time.now
  end
end
