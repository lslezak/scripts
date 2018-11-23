
require "yaml"
module Y2status
  # OBS log analyzer
  class ObsLogAnalyzer < LogAnalyzer
    def initialize(log)
      super
    end

  private

    def config_file
      File.join(__dir__, "../../config/obs_rules.yml")
    end
  end
end
