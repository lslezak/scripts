
require "yaml"
module Y2status
  # Jenkins log analyzer
  class JenkinsLogAnalyzer < LogAnalyzer

    def initialize(log)
      super
    end

    # Return the author of the related commit, works only
    # when the job was started via the web hook. For builds started by
    # the scheduler this information is not present.
    #
    # @return [String] The name or empty string if not found
    # @note you can use https://github.com/<author>.png?size=32 image in the UI
    def author
      return @author if @author

      @author = if log =~ /Started by GitHub push by (.*)$/
        Regexp.last_match[1]
      else
        ""
      end
    end

  private

    def config_file
      File.join(__dir__, "../../config/jenkins_errors.yml")
    end
  end
end
