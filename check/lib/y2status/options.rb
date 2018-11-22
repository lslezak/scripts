
require "optparse"
require "singleton"

# parse and store the command line options
module Y2status
  class Options
    include Singleton

    attr_reader :verbose, :public_only

    def initialize
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

        opts.on("-p", "--public", "Query only the public services (default: false)") do |p|
          @public_only = p
        end

        opts.on("-v", "--[no-]verbose", "Run verbosely (default: false)") do |v|
          @verbose = v
        end

      end.parse!
    rescue OptionParser::InvalidOption => e
      $stderr.puts "Error: #{e.message}"
      exit 1
    end
  end
end
