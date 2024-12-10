# frozen_string_literal: true

require "phlex"

module Phlexi
  module Menu
    class Item
      attr_reader :label, :url, :icon, :leading_badge, :trailing_badge, :items, :options

      def initialize(label, url: nil, icon: nil, leading_badge: nil, trailing_badge: nil, **options, &)
        @label = label
        @url = url
        @icon = icon
        @leading_badge = leading_badge
        @trailing_badge = trailing_badge
        @options = options
        @items = []

        yield self if block_given?
      end

      def item(label, **, &)
        new_item = self.class.new(label, **, &)
        @items << new_item
        new_item
      end

      def active?(context)
        return @options[:active].call(context) if @options[:active].respond_to?(:call)
        return context.current_page?(@url) if @url

        @items.any? { |item| item.active?(context) }
      end
    end
  end
end
