# TODO

* Specs
* Update feed URI on permanent redirect
* Do not mark entry as sent if email was not sent
* Speed up feed fetches by comparing against a previously calculated checksum
* Show entry metadata in email (e.g. pubdate, author)
* Implement a command-line interface to manage feeds.yml
* Detect entry URI changes (maybe by comparing body hashes?)
* Filters (e.g. skip entries matching a pattern)
* Support "dispatch interfaces" where email is one such interface (another could
  be writing to the filesystem)
* Profiles (support many feed lists and recipients)
* Send email notifications to user (e.g. when a feed is not available anymore)
* Plugin architecture
