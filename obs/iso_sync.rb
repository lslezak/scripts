#! /usr/bin/env ruby

# This script synchronizes the files matching a specified regexp from a remote
# FTP server.
#
# Examples:
#
# openSUSE Leap sync:
#
#  ./iso_sync.rb -d 180 -u ftp://mirrors.nic.cz/pub/opensuse/opensuse/distribution/leap/15.0/iso/ \
#    -p '^openSUSE-Leap-15.0-NET-x86_64-Build.*-Media\.iso$,\
#    ^openSUSE-Leap-15.0-DVD-x86_64-Build.*-Media\.iso$'
#
# SLE sync:
#
#  ./iso_sync.rb -d 15 -u ftp://dist.nue.suse.com/ibs/SUSE:/SLE-15:/GA:/TEST/images/iso/ \
#    -p '^SLE-15-Installer-DVD-x86_64-Build.*-Media1\.iso$,\
#    ^SLE-15-Packages-x86_64-Build.*-Media1\.iso$'
#

require "net/ftp"
require "uri"
require "logger"
require "optparse"
require "optparse/uri"

uri = nil
patterns = [/.*/]
delay = 15

def logger
  @logger ||= Logger.new($stdout, level: Logger::INFO)
end

OptionParser.new do |parser|
  parser.on("-u", "--url URL", URI, "URL to watch, must be an ftp:// URL!") do |u|
    uri = u
  end

  parser.on("-p", "--pattern x,y,z", Array, "File patterns to download (regexps)") do |list|
    patterns = list.map { |p| Regexp.new(p) }
  end

  parser.on("-d", "--delay minutes", Integer, "The delay before the next check (in minutes)") do |d|
    delay = d
  end

  parser.on("-v", "--verbose", "Enable verbose (debugging) output") do
    logger.level = Logger::DEBUG
  end
end.parse!

logger.debug { "URL: #{uri.inspect}" }
logger.debug { "Files: #{patterns.inspect}" }

if uri.nil?
  $stderr.puts "Missing -u (--url) parameter!"
  exit 1
end

def download(uri, file)
  Net::FTP.open(uri.host) do |ftp|
    ftp.login
    ftp.chdir(uri.path)
    ftp.getbinaryfile(file, file + ".downloading")
    File.rename(file + ".downloading", file)
  end
end

def list_files(uri)
  Net::FTP.open(uri.host) do |ftp|
    ftp.login
    ftp.chdir(uri.path)
    return ftp.nlst
  end
end

def download_missing_file(uri, file)
  if File.exist?(file)
    logger.debug { "File #{file} already exists" }
    return
  end

  logger.info "Downloading #{file} ..."
  download(uri, file)
  logger.info "Done"
end

loop do
  logger.debug "Reading remote files..."
  files = list_files(uri).sort.reverse
  logger.debug { "Read #{files.size} remote files" }

  latest = patterns.each_with_object([]) do |p, list|
    file = files.find { |f| f.match(p) }
    list << file if file
  end

  latest.each do |l|
    download_missing_file(uri, l)
  end

  logger.debug "Sleeping for #{delay} minutes..."
  sleep(delay * 60)
end
