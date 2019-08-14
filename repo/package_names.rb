#! /usr/bin/env ruby

# This script extracts the package names from the raw RPM-MD repository metadata.
# 
# Note: parsing big XML files might take quite some time, Leap 15.1 OSS
#       repo with 36000 packages takes 40-60 seconds (depending on the CPU power)
#
# Usage:
#
# a) - download the *-primary.xml.gz file from a remote repository,
#       e.g. from https://download.opensuse.org/distribution/leap/15.1/repo/oss/repodata/
#    - run: ./package_names.rb *-primary.xml.gz
#
# b) - mount a local ISO: mount /local/foo.iso /mnt
#    - scan all subdirs: /package_names.rb /mnt
#
# c) - use the libzypp repository cache
#    - use all current repositories: ./package_names.rb /var/cache/zypp/raw/
#    - just a selected repo: ./package_names.rb /var/cache/zypp/raw/openSUSE-15.0
#

require "zlib"
require "rexml/document"
require "rexml/streamlistener"

# allow aborting via Ctr+C
Signal.trap('INT') { puts "Aborted"; exit 1 }
Signal.trap('TERM') { puts "Aborted"; exit 1 }

class Package
  attr_reader :name, :version, :arch

  def initialize(name, version, arch)
    @name = name
    @version = version
    @arch = arch
  end
end

# use the XML SAX (streaming) parser,
# the uncompressed TW XML has ~120MB!
class PackageListener
  include REXML::StreamListener

  attr_reader :packages
  
  def initialize
    @packages = []
  end
   
  def tag_start(tag, attrs)
    if tag == "package"
      @package_version = nil
    elsif tag == "name"
      @in_name_tag = true
    elsif tag == "version"
      @package_version = "#{attrs["ver"]}-#{attrs["rel"]}"
    elsif tag == "arch"
      @in_arch_tag = true
    end
  end
  
  def text(data)
    @package_name = data if @in_name_tag
    @package_arch = data if @in_arch_tag
  end
  
  def tag_end(tag)
    @in_name_tag = false if tag == "name"
    @in_version_tag = false if tag == "version"

    if tag == "package" 
      packages << Package.new(@package_name, @package_version, @package_arch)
    end
  end
end

def packages_from_meta(file)
  $stderr.puts "Processing #{file}..."

  l = PackageListener.new

  Zlib::GzipReader.open(file) do |gz|
    REXML::Document.parse_stream(gz, l)
  end

  l.packages
end

packages = []

# the argument is a file
if ARGV[0] && File.file?(ARGV[0])
  packages = packages_from_meta(ARGV[0])
else
  # otherwise treat the argument as a dir,
  # use the current dir if no argument passed
  Dir[File.join(ARGV[0] || Dir.pwd, "/**/*-primary.xml.gz") ].each do |f|
    packages.concat(packages_from_meta(f))
  end
end

# print the summary
packages.each { |p| puts "#{p.name}-#{p.version}-#{p.arch}" }
