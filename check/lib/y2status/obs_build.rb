
module Y2status
  class ObsBuild
    attr_reader :package, :target, :status

    def initialize(package, target, status)
      @package = package
      @target = target
      @status = status
    end

    def status_label
      status
    end

    def status_type
      case status
      when "failed", "broken", "unresolvable"
        :error
      when "succeeded"
        :success
      when "disabled", "excluded"
        :unknown
      else
        :unknown
      end
    end
  end
end
