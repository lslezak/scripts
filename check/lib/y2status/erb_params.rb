
require "erb"

module Y2status
  class ErbParams
    include ERB::Util
    include Y2status::Helpers

    def initialize(params)
      params.each do |key, value|
        singleton_class.send(:define_method, key) { value }
      end
    end

    def get_binding
      binding
    end
  end
end
