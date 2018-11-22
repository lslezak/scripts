require "erb"

module Y2status
  class ErbRenderer
    attr_reader :template

    def initialize(template)
      @template = template
    end

    def render(params = {})
      file = File.join(__dir__, "../../views", template)
      renderer = ERB.new(File.read(file))
      renderer.filename = file
      erb_params = ErbParams.new(params)
      renderer.result(erb_params.get_binding)
    end
  end

end