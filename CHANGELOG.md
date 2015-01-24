### 0.9.0

* Change data backend from YAML to SQLite3
* Add `send_method` config option to send emails with
* Add `file` send method for writing emails to a file
* Add `backend` command to open an SQLite3 db shell
* Add `config` command to open config with `$EDITOR`
* Add `import`/`export` command to import/export feed subscriptions as OPML
* Remove `history` command
* Provide a single script for migrating (`feed2email-migrate`)

### 0.8.0

* Command-line interface for managing feeds
* Perform feed autodiscovery in `add` command
* Store feed metadata in feed list, so no more feed files
* Add `f2e` symlink to `feed2email` binary for running convenience
* Improve send delay between entry processing
* Fix feed fetching exception handling
* Sync feed metadata only if all entries are processed
* Record entry to history only if email was sent
* Always fetch feed when permanently redirected
* Ignore redirections to the same location
* Major rewrite of README file with new instructions

### 0.7.0

* Prevent simultaneous running instances
* Support log rotation
* Show entry author and pubdate in email
* Use a single SMTP connection for all email sending
* Rename `smtp_tls` option to `smtp_starttls`

### 0.6.0

* Render text/plain body as Markdown
* Cache feed fetching with Last-Modified and ETag HTTP headers
* Update feed URI on permanent redirect
* Make `sender` a required config option
* Maintain a separate history file per feed

### 0.5.0

* Sanitize SMTP user in from address
* Add config option for sender email address (from)
* Add config option for log verbosity
* Add text/plain part in email messages
* Strip HTML from email subject and body title

### 0.4.0

* Major rewrite to keep history of processed (seen) entries
* Handle feed fetching/parsing errors
* Limit the number of entries to process per feed
* Fix prepending of feed URI to path entry permalinks

### 0.3.0

* Add logging
* Do not sync fetch time if there was an error
* Extract email address from entry author
* Prepend feed URI to path entry permalinks

### 0.2.3

* Isolate feed processing failures

### 0.2.2

* Fix smtp_tls option never being false
* Use SMTP user@host as "from" address if entry author is missing

### 0.2.1

* Add config option to delay mail sending

### 0.2.0

* Add support for sending mail via SMTP
* Replace command-line configuration with a config file

### 0.1.0

* Skip entry if pubDate is in the future
* Fix feed fetching by accepting compression
* Fix crashing for missing multi-level directories in config path
* Accept recipient address as the first command-line argument
* Append feed2email signature to email body
* Use full HTTPS address for RubyGems source in Gemfile
* Add this changelog

### 0.0.1

* Initial release
