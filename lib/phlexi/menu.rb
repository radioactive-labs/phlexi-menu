# frozen_string_literal: true

require "zeitwerk"
require "phlex"
require "active_support/core_ext/object/blank"

module Phlexi
  NIL_VALUE = :__i_phlexi_i__

  module Menu
    Loader = Zeitwerk::Loader.new.tap do |loader|
      loader.tag = File.basename(__FILE__, ".rb")
      loader.ignore("#{__dir__}/menu/version.rb")
      loader.inflector.inflect(
        "phlexi-menu" => "Phlexi",
        "phlexi" => "Phlexi"
      )
      loader.push_dir(File.expand_path("..", __dir__))
      loader.setup
    end

    COMPONENT_BASE = (defined?(::ApplicationComponent) ? ::ApplicationComponent : Phlex::HTML)

    class Error < StandardError; end
  end
end
