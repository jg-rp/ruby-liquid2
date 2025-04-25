# frozen_string_literal: true

require "pathname"

module Liquid2
  # Liquid template source text and meta data.
  class TemplateSource
    attr_reader :source, :name, :up_to_date, :matter

    def initialize(source:, name:, up_to_date: nil, matter: nil)
      @source = source
      @name = name
      @up_to_date = up_to_date
      @matter = matter
    end
  end

  # The base class for all template loaders.
  class TemplateLoader
    # Load and return template source text and any associated data.
    # @param env [Environment] The current Liquid environment.
    # @param name [String] A name or identifier for the target template source text.
    # @param context [RenderContext?] The current render context, if one is available.
    # @param *kwargs Arbitrary arguments that can be used to narrow the template source
    #   search space.
    # @return [TemplateSource]
    def get_source(env, name, context: nil, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
      raise "template loaders must implement `get_source`"
    end

    def load(env, name, globals: nil, context: nil, **kwargs)
      data = get_source(env, name, context: context, **kwargs)
      path = Pathname.new(data.name)
      env.parse(data.source,
                name: path.basename.to_s,
                path: data.name,
                globals: globals,
                up_to_date: data.up_to_date,
                overlay: data.matter)
    end
  end

  # A template loader that reads templates from a hash.
  class HashLoader < TemplateLoader
    # @param templates [Hash<String, String>] A mapping of template names to template source text.
    def initialize(templates)
      super()
      @templates = templates
    end

    def get_source(env, name, context: nil, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
      if (text = @templates[name])
        TemplateSource.new(source: text, name: name)
      else
        raise LiquidTemplateNotFoundError, name
      end
    end
  end
end
