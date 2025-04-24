# frozen_string_literal: true

module Liquid2
  # Base class for all Liquid tags.
  class Tag < Node
    def initialize(token)
      super
      return if token.first == :token_tag_name

      raise "unexpected token kind for tag #{self.class} (#{token})"
    end

    # Render this tag to the output buffer.
    # @param context [RenderContext]
    # @param buffer [String]
    def render(_context, _buffer)
      raise "tags must implement `render: (RenderContext, String) -> void`."
    end
  end
end
