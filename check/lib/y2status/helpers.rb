
module Y2status
  module Helpers
    def status_symbol(obj)
      if obj.success?
        "<span class=\"color_success\">✔</span>"
      else
        "<span class=\"color_error\">✘</span>"
      end
    end
  end
end
