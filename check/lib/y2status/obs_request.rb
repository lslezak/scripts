
module Y2status
  # Build service submit request
  class ObsRequest
    attr_reader :project, :id, :details

    #
    # Constructor
    #
    # @param id [String] Request ID (number)
    # @param details [String] SR description
    #
    def initialize(project, id, details)
      @project = project
      @id = id
      @details = details
    end

    def issue_id
      "declined_sr:#{project.api}_#{id}"
    end
  end
end
