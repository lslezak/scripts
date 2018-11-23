
require "yaml"

module Y2status
  class Config
    attr_reader :file

    def initialize(file = File.join(__dir__, "../../config/config.yml"))
      @file = file
    end

    def configuration
      @configuration ||= load_config
    end

    def jenkins_servers
      (configuration["jenkins"] || []).each_with_object([]) do |j, list|
        next if Options.instance.public_only && j["public"] != false
        list << JenkinsServer.new(j["label"], j["url"])
      end
    end

    def obs_projects
      (configuration["obs"] || []).each_with_object([]) do |o, list|
        next if Options.instance.public_only && o["public"] != false
        list << ObsProject.new(o["project"], o["api"])
      end
    end

    def docker_images
      (configuration["docker"] || []).each_with_object([]) do |i, list|
        list << DockerImage.new(i)
      end
    end

  private

    def load_config
      YAML.load_file(file)
    end
  end
end
