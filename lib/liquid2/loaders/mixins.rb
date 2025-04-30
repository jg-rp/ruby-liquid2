# frozen_string_literal: true

require_relative "../utils/cache"

module Liquid2
  # A mixin that adds caching to a template loader.
  module CachingLoaderMixin
    def initialize_cache(auto_reload: true, namespace_key: "", capacity: 300, thread_safe: false)
      @auto_reload = auto_reload
      @namespace_key = namespace_key
      @cache = if thread_safe
                 ThreadSafeLRUCache.new(capacity)
               else
                 LRUCache.new(capacity)
               end
    end

    def load(env, name, globals: nil, context: nil, **kwargs)
      key = cache_key(name, context: context, **kwargs)

      # @type var template: Liquid2::Template
      # @type var cached_template: Liquid2::Template
      if (cached_template = @cache[key])
        if @auto_reload && cached_template.up_to_date? == false
          template = super
          @cache[key] = template
          template
        else
          cached_template
        end
      else
        template = super
        @cache[key] = template
        template
      end
    end

    def cache_key(name, context: nil, **kwargs)
      return name unless @namespace_key

      key = (@namespace_key || raise).to_sym
      return "#{kwargs[key]}/#{name}" if kwargs.include?(key)
      return name unless context

      if (namespace = context.globals[@namespace_key || raise])
        "#{namespace}/#{name}"
      else
        name
      end
    end
  end
end
