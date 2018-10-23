#! /usr/bin/env ruby
#
# convert images in a blog post
#

file = ARGV[0]
content = File.read(file)

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

File.write(file, content)
