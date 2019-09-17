#! /usr/bin/env ruby

require "jekyll-import"
require_relative "lizards_rss"
require_relative "lizards_html"

# Dir["*.xml"].each do |xml|
#   JekyllImport::Importers::LizardsRSS.run("source" => xml)
# end

# Dir["*.html"].each do |html|
#   importer = LizardsHtmlImporter.new(html)
#   importer.process
# end

system "curl -s https://lizards.opensuse.org/feed/ > feed.xml"
JekyllImport::Importers::LizardsRSS.run("source" => "feed.xml")

Dir["_posts/*.md"].each do |md|
  content = File.read(md)

  regexp1 = format(Regexp.escape("<div class=\"figure\">
[![](../../../../images/%s/%s)](../../../../images/%s/%s)
</div>"), "(.*)", "(.*)", "(.*)", "(.*)")
  replacement1 = "{% include blog_img.md alt=\"\"
  src=\"\\2\" full_img=\"\\4\" %}"
  
  regexp2 = format(Regexp.escape("[![%s
%s](../../../../images/%s/%s)](../../../../images/%s/%s)"),
    "(.*)", "(.*)", "(.*)", "(.*)", "(.*)", "(.*)")
  replacement2 = "{% include blog_img.md alt=\"\\1 \\2\"
src=\"\\4\" full_img=\"\\6\" %}"
  
  regexp3 = format(Regexp.escape("[![](../../../../images/%s/%s)](../../../../images/%s/%s)"),
    "(.*)", "(.*)", "(.*)", "(.*)")
  
  content.gsub!(Regexp.new(regexp1), replacement1)
  content.gsub!(Regexp.new(regexp2), replacement2)
  content.gsub!(Regexp.new(regexp3), replacement1)
  
  File.write(md, content)
end
