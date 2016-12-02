
# Blog Posts Importer

This is an importer for importing the YaST posts from https://lizards.opensuse.org/.

# Pre-requisites

- Ruby + Bundler (`zypper in 'rubygem(bundler)'`)
- HTML to Markdown convertor (`zypper in python-html2text python-setuptools`)

# Process

The convertor uses the patched RSS feed importer (http://import.jekyllrb.com/docs/rss/).

The XML feed contains only the current posts, fortunately the older feeds
can be found in the Web archive at http://web.archive.org/web/*/https://lizards.opensuse.org/feed/

Specifically these old feeds were used (saved to `feed*.xml` files):

- http://web.archive.org/web/20160609193427/https://lizards.opensuse.org/feed/
- http://web.archive.org/web/20160417063652/https://lizards.opensuse.org/feed/
- http://web.archive.org/web/20160306111719/https://lizards.opensuse.org/feed/
- http://web.archive.org/web/20160112084402/https://lizards.opensuse.org/feed/

# Starting the Import

```sh
bundle install --path .vendor/bundle
bundle exec ruby ./lizard_importer.rb
```

The converted posts are saved into `_posts` directory.
