
module Y2status
  # Defines an Jenkins job instance
  class JenkinsJob
    include Downloader

    attr_reader :name, :status, :server

    def initialize(server, name, status)
      @name = name
      @status = status
      @server = server
    end

    def console_url
      "#{server.base_url}/job/#{name}/lastBuild/console"
    end

    def job_url
      "#{server.base_url}/job/#{name}"
    end

    def log_url
      "#{server.base_url}/job/#{name}/lastBuild/consoleText"
    end

    def status_label
      case status
      when "red"
        "failed"
      when "blue"
        "success"
      else
        status
      end
    end

    def status_type
      case status
      when "red"
        :error
      when "blue"
        :success
      when "disabled"
        :info
      else
        :unknown
      end
    end

    def scanner
      @scanner ||= create_scanner
    end

  private

    def create_scanner
      log = download_url(log_url)
      JenkinsLogAnalyzer.new(log)
    end
  end
end
