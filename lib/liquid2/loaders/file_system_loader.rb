# frozen_string_literal: true

require "pathname"
require_relative "../loader"
require_relative "mixins"

module Liquid2
  # A template loader that reads template from a file system.
  class FileSystemLoader < TemplateLoader
    def initialize(search_path, default_extension: nil)
      super()
      @search_path = if search_path.is_a?(Array)
                       search_path.map { |p| Pathname.new(p) }
                     else
                       [Pathname.new(search_path)]
                     end

      @default_extension = default_extension
    end

    def get_source(_env, name, context: nil, **_kwargs)
      path = resolve_path(name)
      mtime = path.mtime
      up_to_date = -> { path.mtime == mtime }
      TemplateSource.new(source: path.read, name: path.to_s, up_to_date: up_to_date)
    end

    def resolve_path(template_name)
      template_path = Pathname.new(template_name)

      # Append the default file extension if needed.
      if @default_extension && template_path.extname.empty?
        template_path = template_path.sub_ext(@default_extension || raise)
      end

      # Don't alow template names to escape the search path with "../".
      template_path.each_filename do |part|
        if part == ".."
          raise LiquidTemplateNotFoundError.new("template not found #{template_name}",
                                                nil)
        end
      end

      # Search each path in turn.
      @search_path.each do |path|
        source_path = path.join(template_path)
        return source_path if source_path.file?
      end

      raise LiquidTemplateNotFoundError.new("template not found #{template_name}", nil)
    end
  end

  # A file system template loader that caches parsed templates.
  class CachingFileSystemLoader < FileSystemLoader
    include CachingLoaderMixin

    def initialize(
      search_path,
      default_extension: nil,
      auto_reload: true,
      namespace_key: "",
      capacity: 300,
      thread_safe: false
    )
      super(search_path, default_extension: default_extension)

      initialize_cache(
        auto_reload: auto_reload,
        namespace_key: namespace_key,
        capacity: capacity,
        thread_safe: thread_safe
      )
    end
  end
end
