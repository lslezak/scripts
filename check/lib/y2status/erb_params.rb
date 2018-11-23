
require "erb"

module Y2status
  # Helper class for passing the parameters to an ERB template
  class ErbParams
    include ERB::Util
    include Y2status::Helpers

    #
    # Initialize the parameters object
    #
    # @param params [Hash] Each key will be mapped to the specified value
    #
    def initialize(params)
      params.each do |key, value|
        singleton_class.send(:define_method, key) { value }
      end
    end

    #
    # Return the binding used for an ERB renderer to access the specified parameters
    #
    # @return [Binding] The Ruby context with access to the parameters
    #
    def context
      binding
    end
  end
end
