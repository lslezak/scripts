module Y2status
  # Docker build result
  class DockerBuild
    attr_reader :tag, :status

    def initialize(tag, status)
      @tag = tag
      @status = status
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
