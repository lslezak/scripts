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

class Pattern
  attr_reader :name, :src_name, :icon

  def initialize(name, src, icon)
    @name = name
    @src_name = src
    @icon = icon
  end
end

# use the XML SAX (streaming) parser,
# the uncompressed Leap 15.1 XML is ~97MB!
class Listener
  include REXML::StreamListener

  attr_reader :patterns
  
  def initialize
    @patterns = []
  end
   
  def tag_start(tag, attrs)
    if tag == "name"
      @in_name_tag = true
    elsif tag == "rpm:provides"
      @in_provides = true
      @icon = nil
      @visible = false
    elsif tag == "rpm:entry" && @in_provides
      if attrs["name"] == "pattern-visible()"
        @visible = true
      elsif attrs["name"] == "pattern-icon()"
        @icon = attrs["ver"]
        rel = attrs["rel"]

        @icon << "-" << rel if rel && !rel.empty?
      end
    elsif tag == "rpm:sourcerpm"
      @in_src_rpm = true
    end
  end
  
  def text(data)
    @package = data if @in_name_tag
    @src_package = data if @in_src_rpm
  end
  
  def tag_end(tag)
    @in_name_tag = false if tag == "name"
    @in_src_rpm = false if tag == "rpm:sourcerpm"
    if tag == "rpm:provides" 
      # ignore icons for invisible patterns
      # normally should not happen, but there are some =:-O
      patterns << Pattern.new(@package, @src_package, @icon) if @icon && @visible

      # if @icon && !@visible
      #   puts "WARNING: #{@package} invisible icon #{@icon}"
      # end
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

  l.patterns
end

patterns = []

# the argument is a file
if ARGV[0] && File.file?(ARGV[0])
  patterns = icons_from_meta(ARGV[0])
else
  # otherwise treat the argument as a dir,
  # use the current dir if no argument passed
  Dir[File.join(ARGV[0] || Dir.pwd, "/**/*-primary.xml.gz") ].each do |f|
    patterns.concat(icons_from_meta(f))
  end
end

# print the summary
puts "Pattern Icons"
puts "=============\n\n"
patterns.each { |p| puts "#{p.name} (#{p.src_name}): #{p.icon}" }

puts
puts "Unique Icon Names"
puts "=================\n\n"
puts patterns.map(&:icon).sort.uniq.join("\n")
