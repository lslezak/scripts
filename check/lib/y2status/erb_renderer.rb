require "erb"

module Y2status
  # Helper class for rendering the ERB templates
  class ErbRenderer
    attr_reader :template
    #
    # Initialize the renderer
    #
    # @param template [String] The template file name (located in the "views" subdirectory)
    #
    def initialize(template)
      @template = template
    end

    #
    # Render the template using the specified parameters
    #
    # @param params [Hash] Parameter mapping, the key defines the name for accessing the parameter,
    #   the values define the value to use
    #
    # @return [String] Rendered result
    #
    def render(params = {})
      file = File.join(__dir__, "../../views", template)
      renderer = ERB.new(File.read(file))
      renderer.filename = file
      erb_params = ErbParams.new(params)
      renderer.result(erb_params.context)
    end
  end
end
