#! /usr/bin/env ruby

# This scans the products available at the given URL.
#
# Usage: product_scanner.rb <URL>
#
# <URL> is the product URL, it works also with local ISO images:
#   iso:/?iso=image.iso&url=dir:///path/to/the/image
# (Do not forget to quite the URL in shell...)

require "yast"
require "pp"

url = ARGV[0]

Yast.import "Pkg"

# read the trusted GPG keys from the current system
Yast::Pkg.TargetInitialize("/")

# add the repository
Yast::Pkg.RepositoryAdd("base_urls" => [url])
Yast::Pkg.SourceLoad

# list the products
products = Yast::Pkg.ResolvableProperties("", :product, "")
# truncate the license text, it's just too long...
products.each {|p| p["license"] = p["license"][0..50] + "..."  }
pp products
