# frozen_string_literal: true

require "phlex"

module Phlexi
  module Menu
    module Builder
      attr_reader :items

      class Item < Phlexi::Menu::Item; end

      def initialize(&)
        @items = []

        yield self if block_given?
      end

      def item(label, **, &)
        new_item = self.class::Item.new(label, **, &)
        @items << new_item
        new_item
      end
    end
  end
end
