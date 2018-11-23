
require "yaml"
module Y2status
  # Jenkins log analyzer
  class JenkinsLogAnalyzer
    attr_reader :log

    def initialize(log)
      @log = log
    end

    #
    # Analyze the logs
    #
    # @return [Pair<Array<String>, Array<String>>] The pair containing list of errors
    #  and list of suggested actions.
    #
    def analyze
      errors = []
      actions = []

      rules.each do |rule|
        next unless log =~ Regexp.new(rule["match"])

        errors << rule["desc"]
        actions << rule["action"]
      end

      [errors, actions]
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

    def rules
      # make the location configurable?
      @rules ||= YAML.load_file(File.join(__dir__, "../../config/jenkins_rules.yml"))
    end
  end
end
