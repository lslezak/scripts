#! /usr/bin/env ruby

# This script extracts the /usr/etc file names from the raw RPM-MD repository metadata.

require "zlib"
require "rexml/document"
require "rexml/streamlistener"

# allow aborting via Ctr+C
Signal.trap('INT') { $stderr.puts "Aborted"; exit 1 }
Signal.trap('TERM') { $stderr.puts "Aborted"; exit 1 }

# use the XML SAX (streaming) parser,
# the uncompressed Leap 15.1 XML is ~97MB!
class Listener
  include REXML::StreamListener

  attr_reader :files
  
  def initialize
    @files = []
  end
   
  def tag_start(tag, attrs)
    if tag == "file"
      @in_file_tag = true
    end
  end
  
  def text(data)
    @file = data if @in_file_tag
  end
  
  def tag_end(tag)
    if tag == "file" 
      files << @file if @file.start_with?("/usr/etc/")
      @in_file_tag = false
    end
  end
end

def files_from_xml(file)
  $stderr.puts "Processing #{file}..."

  l = Listener.new

  Zlib::GzipReader.open(file) do |gz|
    REXML::Document.parse_stream(gz, l)
  end

  l.files
end

files = []

# the argument is a file
if ARGV[0] && File.file?(ARGV[0])
  files = files_from_xml(ARGV[0])
else
  # otherwise treat the argument as a dir,
  # use the current dir if no argument passed
  Dir[File.join(ARGV[0] || Dir.pwd, "/**/*-filelists.xml.gz") ].each do |f|
    files.concat(files_from_xml(f))
  end
end

files.uniq!
files.sort!

puts files
puts "Found #{files.size} files"
