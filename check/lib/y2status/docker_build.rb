module Y2status
  # Docker build result
  class DockerBuild
    attr_reader :image, :tag, :status

    def initialize(image, tag, status)
      @image = image
      @tag = tag
      @status = status
    end

    def issue_id
      "docker:#{image.image}:#{tag}"
    end

    def failure?
      status == -1
    end

    def status_label
      # "status" values:
      #     -1 = failed
      #   0..9 = building
      #     10 = success
      case status
      when -1
        "failed"
      when -4
        "canceled"
      when 10
        "success"
      when 0..9
        "building"
      else
        "unknown (#{status})"
      end
    end

    def status_type
      case status
      when -1
        :error
      when 10
        :success
      when 0..9, -4
        :info
      else
        :unknown
      end
    end
  end
end
