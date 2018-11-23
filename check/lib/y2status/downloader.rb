
require "shellwords"

module Y2status
  # Helper methods for downloading URLs
  module Downloader
    include Reporter

    #
    # Download the resource
    #
    # @param url [String] URL to download
    #
    # @return [String] Downloaded page, empty string if download failed
    #
    def download_url(url)
      print_progress("Downloading #{url}...")
      # -s silent, -L follow redirects
      `curl --connect-timeout 15 --max-time 30 -sL #{Shellwords.escape(url)}`
    end
  end
end
