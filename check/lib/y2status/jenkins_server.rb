
module Y2status
  # Jenkins server
  class JenkinsServer
    include Downloader
    include Reporter

    attr_reader :base_url, :label, :error, :ignore

    def initialize(label, base_url, ignore)
      puts "#{base_url}: #{ignore.inspect}"
      @label = label
      @base_url = base_url
      @ignore = ignore || []
      @ignore.map!{|i| Regexp.new(i)}
    end

    def error?
      error && !error.empty?
    end

    def success?
      !jobs.any?(&:failure?)
    end

    def issues
      jobs.count(&:failure?)
    end

    def jobs
      @jobs ||= download
    end

  private

    def status_url
      "#{base_url}/api/json?pretty=true"
    end

    def download
      body = download_url(status_url)

      if body.empty?
        @error = "Cannot download #{status_url}"
        print_error(error)
        return []
      end

      data = JSON.parse(body)

      # list of jobs or a single job
      jobs = data.key?("jobs") ? data["jobs"] : data

      if ignore
        jobs.reject! do |j|
          next true unless j["name"] && j["color"]
          ignore.any?{|i| j["name"] =~ i}
        end
      end

      jobs.map do |s|
        puts "s: #{s.inspect}"
        JenkinsJob.new(self, s["name"], s["color"])
      end
    end
  end
end
