
require "yaml"
module Y2status
  # Base class for log analyzers
  class LogAnalyzer
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

  private

    def rules
      @rules ||= (YAML.safe_load(File.read(config_file)) + YAML.safe_load(File.read(generic_rules)))
    end

    def generic_rules
      File.join(__dir__, "../../config/generic_rules.yml")
    end
  end
end
