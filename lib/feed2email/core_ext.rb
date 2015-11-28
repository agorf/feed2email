require 'cgi'
require 'reverse_markdown'
require 'sanitize'

class Numeric
  def megabytes
    self * 1024 * 1024
  end
end

class String
  def escape_html
    CGI.escapeHTML(self)
  end

  def numeric?
    !!(self =~ /\A\d+\z/)
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
