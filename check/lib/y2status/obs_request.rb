
module Y2status
  # Build service submit request
  class ObsRequest
    attr_reader :id, :details

    #
    # Constructor
    #
    # @param id [String] Request ID (number)
    # @param details [String] SR description
    #
    def initialize(id, details)
      @id = id
      @details = details
    end
  end
end
