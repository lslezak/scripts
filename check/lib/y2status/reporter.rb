
module Y2status
  module Reporter
    def print_progress(msg)
      $stderr.puts(msg) if Options.instance.verbose
    end

    def print_error(msg)
      $stderr.puts(msg)
    end
  end
end
