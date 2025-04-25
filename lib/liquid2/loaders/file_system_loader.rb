# frozen_string_literal: true

require "pathname"
require_relative "../loader"

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
      unless @default_extension.nil? || !template_path.extname.empty?
        template_path = template_path.sub_ext(@default_extension || raise)
      end

      template_path.each_filename do |part|
        raise LiquidTemplateNotFoundError.new(template_name.to_s, nil) if part == ".."
      end

      @search_path.each do |path|
        source_path = path.join(template_name)
        return source_path if source_path.file?
      end

      raise LiquidTemplateNotFoundError.new(template_name.to_s, nil)
    end
  end
end
