
module Y2status
  # HTML formatting helpers
  module Helpers
    #
    # HTML text with rendered result symbol
    #
    # @param obj [#success?] Object responding to #success? call
    #
    # @return [String] HTMl text
    #
    def status_symbol(obj)
      return "❓" unless obj.respond_to?(:success?)

      if obj.success?
        "<span class=\"color_success\">✔</span>"
      else
        "<span class=\"color_error\">✘</span>"
      end
    end
  end
end
