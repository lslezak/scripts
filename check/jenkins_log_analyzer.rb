
require "yaml"

class JenkinsLogAnalyzer
  attr_reader :log

  def initialize(log)
    @log = log
  end

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

  # Note: use https://github.com/<author>.png?size=32 image in UI
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
    @rules ||= YAML.load_file(File.join(__dir__, "jenkins_rules.yml"))
  end
end
