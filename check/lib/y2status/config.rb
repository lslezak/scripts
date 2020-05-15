
require "yaml"

module Y2status
  # Class for reading the project config file
  class Config
    attr_reader :file

    #
    # Constructor
    #
    # @param file [String] Path to the config file
    #
    def initialize(file = Options.instance.config)
      @file = file
    end

    #
    # The loaded configuration
    #
    # @return [Hash] The parsed content of the configuration file
    #
    def configuration
      @configuration ||= load_config
    end

    def jenkins_servers
      (configuration["jenkins"] || []).each_with_object([]) do |j, list|
        next if Options.instance.public_only && j["internal"]
        list << JenkinsServer.new(j["label"], j["url"], j["ignore"])
      end
    end

    def obs_projects
      (configuration["obs"] || []).each_with_object([]) do |o, list|
        next if Options.instance.public_only && o["internal"]
        list << ObsProject.new(o["project"], api: o["api"], packages: o["packages"])
      end
    end

    def docker_images
      (configuration["docker"] || []).each_with_object([]) do |i, list|
        list << DockerImage.new(i)
      end
    end

  private

    def load_config
      YAML.safe_load(File.read(file))
    end
  end
end
