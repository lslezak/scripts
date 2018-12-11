#! /usr/bin/env ruby

# This script extracts the pattern icon names from the raw RPM-MD repository metadata.
# 
# Note: parsing big XML files might take quite some time, Leap 15.1 OSS
#       repo with 36000 packages takes 40-60 seconds (depending on the CPU power)
#
# Usage:
#
# a) - download the *-primary.xml.gz file from a remote repository,
#       e.g. from https://download.opensuse.org/distribution/leap/15.1/repo/oss/repodata/
#    - run: ./pattern_icons.rb *-primary.xml.gz
#
# b) - mount a local ISO: mount /local/foo.iso /mnt
#    - scan all subdirs: /pattern_icons.rb /mnt
#
# c) - use the libzypp repository cache
#    - use all current repositories: ./pattern_icons.rb /var/cache/zypp/raw/
#    - just a selected repo: ./pattern_icons.rb /var/cache/zypp/raw/openSUSE-15.0
#

require "zlib"
require "rexml/document"
require "rexml/streamlistener"

# allow aborting via Ctr+C
Signal.trap('INT') { puts "Aborted"; exit 1 }
Signal.trap('TERM') { puts "Aborted"; exit 1 }

# use the XML SAX (streaming) parser,
# the uncompressed Leap 15.1 XML is ~97MB!
class Listener
  include REXML::StreamListener

  attr_reader :pattern_icons
  
  def initialize
    @pattern_icons = {}
  end
   
  def tag_start(tag, attrs)
    if tag == "name"
      @in_name_tag = true
    end

    if tag == "rpm:provides"
      @in_provides = true
      @icon = nil
      @visible = false
    end

    if tag == "rpm:entry" && @in_provides
      if attrs["name"] == "pattern-visible()"
        @visible = true
      elsif attrs["name"] == "pattern-icon()"
        @icon = attrs["ver"]
        rel = attrs["rel"]

        @icon << "-" << rel if rel && !rel.empty?
      end
    end
  end
  
  def text(data)
    @package = data if @in_name_tag
  end
  
  def tag_end(tag)
    @in_name_tag = false if tag == "name"
    if tag == "rpm:provides" 
      # ignore icons for invisible patterns
      # normally should not happen, but there are some =:-O
      pattern_icons[@package] = @icon if @icon && @visible
      @in_provides = false
    end
  end
end

def icons_from_meta(file)
  $stderr.puts "Processing #{file}..."

  l = Listener.new

  Zlib::GzipReader.open(file) do |gz|
    REXML::Document.parse_stream(gz, l)
  end

  l.pattern_icons  
end

icons = {}

# the argument is a file
if ARGV[0] && File.file?(ARGV[0])
  icons = icons_from_meta(ARGV[0])
else
  # otherwise treat the argument as a dir,
  # use the current dir if no argument passed
  Dir[File.join(ARGV[0] || Dir.pwd, "/**/*-primary.xml.gz") ].each do |f|
    icons.merge!(icons_from_meta(f))
  end
end

# print the summary
puts "Pattern Icons"
puts "=============\n\n"
icons.each { |p, i| puts "#{p}: #{i}" }

puts
puts "Unique Icon Names"
puts "=================\n\n"
puts icons.values.sort.uniq.join("\n")
