require 'mail'
require 'feed2email/core_ext/string_refinements'
require 'feed2email/version'

module Feed2Email
  class Email
    using CoreExt::StringRefinements

    def initialize(from:, to:, subject:, html_body:)
      @from      = from
      @to        = to
      @subject   = subject
      @html_body = html_body
    end

    def deliver!
      build_mail.deliver!
    end

    private

    attr_reader :from, :html_body, :options, :subject, :to

    def body_html
      %{
        <html>
        <body>
        #{html_body}
        <p>--<br>
        Sent by <a href="https://github.com/agorf/feed2email">feed2email
        #{VERSION}</a></p>
        </body>
        </html>
      }.lstrip_lines
    end

    def body_text
      body_html.to_markdown
    end

    def build_mail
      Mail.new.tap do |m|
        m.from      = from
        m.to        = to
        m.subject   = subject
        m.html_part = build_mail_part('text/html', body_html)
        m.text_part = build_mail_part('text/plain', body_text)
      end
    end

    def build_mail_part(content_type, body)
      part = Mail::Part.new
      part.content_type = "#{content_type}; charset=UTF-8"
      part.body = body
      part
    end
  end
end
