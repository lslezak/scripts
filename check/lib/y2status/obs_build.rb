
module Y2status
  # Open Build Service build result
  class ObsBuild
    include Reporter

    attr_reader :project, :package, :target, :status

    def initialize(project, package, target, status)
      @project = project
      @package = package
      @target = target
      @status = status
    end

    def failure?
      ["failed", "broken", "unresolvable"].include?(status)
    end

    def issue_id
      "obs_build:#{project.api}_#{project.name}_#{package}_#{target}"
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

    def scanner
      @scanner ||= create_scanner
    end

  private

    def create_scanner
      log = download_log
      ObsLogAnalyzer.new(log)
    end

    def download_log
      opt = project.api ? "-A #{Shellwords.escape(project.api)} " : ""
      param = "#{project.name}/#{package}/#{target}"
      cmd = "osc #{opt}remotebuildlog -s #{Shellwords.escape(param)}"

      print_progress("Running \"#{cmd}\"...")

      begin
        str = Timeout.timeout(15) { `#{cmd}` }
      rescue Timeout::Error
        @error_status = "ERROR: Command #{cmd} timed out"
        print_error(@error_status)
        return ""
      end

      str
    end
  end
end
