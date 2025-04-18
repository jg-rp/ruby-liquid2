# frozen_string_literal: true

module Liquid2
  # Base class for all Liquid tags.
  class Tag < Node
    # Render this node to the output buffer.
    # @param context [RenderContext]
    # @param buffer [StringIO]
    # @return [Integer] The number of bytes written to _buffer_.
    def render(_context, _buffer)
      raise "tag nodes must implement `render: (RenderContext, _Buffer) -> Integer`."
    end
  end
end
