
module Y2status
  # Helper methods for reporting progress or errors
  module Reporter
    #
    # Print a progress message on STDERR. Only in verbose mode,
    # in normal mode does not do anything
    #
    # @param msg [String] the message
    def print_progress(msg)
      $stderr.puts(msg) if Options.instance.verbose
    end

    # Print an error message on STDERR.
    #
    # @param msg [String] the message
    def print_error(msg)
      $stderr.puts(msg)
    end
  end
end
