
require "optparse"
require "singleton"

# parse and store the command line options
module Y2status
  class Options
    include Singleton

    attr_reader :verbose, :public_only, :config, :output

    def initialize
      # the default configuration file
      @config = File.join(__dir__, "../../config/config.yml")

      OptionParser.new do |opts|
        opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

        opts.on("-c", "--config CONFIG_FILE", "Project configuration file (default: #{File.expand_path(config)})") do |c|
          @config = c
        end

        opts.on("-o", "--output HTML_FILE", "Save the generate HTML page to this file (default: STDOUT)") do |o|
          @output = o
        end

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
