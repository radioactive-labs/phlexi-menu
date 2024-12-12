# frozen_string_literal: true

require "phlex"

module Phlexi
  module Menu
    # A component for rendering badge elements in menus
    #
    # @example Basic usage
    #   Badge.new("New!", class: "badge-primary")
    #
    # @example With custom styling
    #   Badge.new("2", class: "badge-notification")
    #
    class Badge < COMPONENT_BASE
      # Initialize a new badge component
      #
      # @param content [String] The text content to display in the badge
      # @param options [Hash] Additional HTML attributes for the badge element
      # @option options [String] :class CSS classes to apply to the badge
      def initialize(content, **options)
        @content = content
        @options = options
        super()
      end

      def view_template
        span(class: @options[:class]) { @content }
      end
    end
  end
end
