# frozen_string_literal: true

module Phlexi
  module Menu
    # Builder class for constructing hierarchical menu structures.
    # Provides a DSL for creating nested menu items with support for labels,
    # URLs, icons, and badges.
    #
    # @example Basic usage
    #   menu = Phlexi::Menu::Builder.new do |m|
    #     m.item "Home", url: "/"
    #     m.item "Products", url: "/products" do |products|
    #       products.item "All Products", url: "/products"
    #       products.item "Add Product", url: "/products/new"
    #     end
    #   end
    class Builder
      # @return [Array<Phlexi::Menu::Item>] The collection of top-level menu items
      attr_reader :items

      # Nested Item class that inherits from Phlexi::Menu::Item
      class Item < Phlexi::Menu::Item; end

      # Initializes a new menu builder.
      #
      # @yield [builder] Passes the builder instance to the block for menu construction
      # @yieldparam builder [Phlexi::Menu::Builder] The builder instance
      def initialize(&)
        @items = []

        yield self if block_given?
      end

      # Creates and adds a new menu item to the current menu level.
      #
      # @param label [String] The display text for the menu item
      # @param ** [Hash] Additional options passed to the Item constructor
      # @yield [item] Optional block for adding nested menu items
      # @yieldparam item [Phlexi::Menu::Item] The newly created menu item
      # @return [Phlexi::Menu::Item] The created menu item
      # @raise [ArgumentError] If the label is nil
      def item(label, **, &)
        raise ArgumentError, "Label cannot be nil" unless label

        new_item = self.class::Item.new(label, **, &)
        @items << new_item
        new_item
      end

      # Checks if the menu has any items.
      #
      # @return [Boolean] true if the menu has no items, false otherwise
      def empty?
        @items.empty?
      end

      # Returns the number of top-level items in the menu.
      #
      # @return [Integer] The count of top-level menu items
      def size
        @items.size
      end

      # Checks if this menu item has any nested items.
      #
      # @return [Boolean] true if the item has nested items, false otherwise
      def nested?
        !empty?
      end

      # Returns a string representation of the menu structure.
      #
      # @return [String] A human-readable representation of the menu
      def inspect
        "#<#{self.class} items=#{@items.map(&:inspect)}>"
      end
    end
  end
end
