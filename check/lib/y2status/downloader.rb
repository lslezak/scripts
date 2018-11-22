
require "shellwords"

module Y2status
  module Downloader
    include Reporter

    def download_url(url)
      print_progress("Downloading #{url}...")
      # -s silent, -L follow redirects
      `curl --connect-timeout 15 --max-time 30 -sL #{Shellwords.escape(url)}`
    end
  end
end