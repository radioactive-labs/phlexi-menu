# frozen_string_literal: true

module Phlexi
  module Menu
    # Represents a single menu item in the navigation hierarchy.
    # Each item can have a label, URL, icon, badges, and nested child items.
    #
    # @example Basic menu item
    #   item = Item.new("Home", url: "/")
    #
    # @example Menu item with badges and icon
    #   item = Item.new("Products",
    #     url: "/products",
    #     icon: ProductIcon,
    #     leading_badge: "New",
    #     trailing_badge: "5")
    #
    # @example Nested menu items
    #   item = Item.new("Admin") do |admin|
    #     admin.item "Users", url: "/admin/users"
    #     admin.item "Settings", url: "/admin/settings"
    #   end
    class Item
      # @return [String] The display text for the menu item
      attr_reader :label

      # @return [String, nil] The URL the menu item links to
      attr_reader :url

      # @return [Class, nil] The icon component class to be rendered
      attr_reader :icon

      # @return [String, Component, nil] The badge displayed before the label
      attr_reader :leading_badge

      # @return [String, Component, nil] The badge displayed after the label
      attr_reader :trailing_badge

      # @return [Array<Item>] Collection of nested menu items
      attr_reader :items

      # @return [Hash] Additional options for customizing the menu item
      attr_reader :options

      # Initializes a new menu item.
      #
      # @param label [String] The display text for the menu item
      # @param url [String, nil] The URL the menu item links to
      # @param icon [Class, nil] The icon component class
      # @param leading_badge [String, Component, nil] Badge displayed before the label
      # @param trailing_badge [String, Component, nil] Badge displayed after the label
      # @param options [Hash] Additional options (e.g., :active for custom active state logic)
      # @yield [item] Optional block for adding nested items
      # @yieldparam item [Item] The newly created menu item
      # @raise [ArgumentError] If the label is nil or empty
      def initialize(label, url: nil, icon: nil, leading_badge: nil, trailing_badge: nil, **options, &)
        raise ArgumentError, "Label cannot be nil" unless label

        @label = label
        @url = url
        @icon = icon
        @leading_badge = leading_badge
        @trailing_badge = trailing_badge
        @options = options
        @items = []

        yield self if block_given?
      end

      # Creates and adds a nested menu item.
      #
      # @param label [String] The display text for the nested item
      # @param ** [Hash] Additional options passed to the Item constructor
      # @yield [item] Optional block for adding further nested items
      # @yieldparam item [Item] The newly created nested item
      # @return [Item] The created nested item
      def item(label, **, &)
        new_item = self.class.new(label, **, &)
        @items << new_item
        new_item
      end

      # Determines if this menu item should be shown as active.
      # Checks in the following order:
      # 1. Custom active logic if provided in options
      # 2. URL match with current page
      # 3. Active state of any child items
      #
      # @param context [Object] The context object (typically a controller) for active state checking
      # @return [Boolean] true if the item should be shown as active, false otherwise
      def active?(context)
        # First check custom active logic if provided
        return @options[:active].call(context) if @options[:active].respond_to?(:call)

        # Then check if this item's URL matches current page
        if context.respond_to?(:helpers) && @url
          return true if context.helpers.current_page?(@url)
        end

        # Finally check if any child items are active
        @items.any? { |item| item.active?(context) }
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

      # Returns a string representation of the menu item.
      #
      # @return [String] A human-readable representation of the menu item
      def inspect
        "#<#{self.class} label=#{@label} url=#{@url} items=#{@items.map(&:inspect)}>"
      end
    end
  end
end
