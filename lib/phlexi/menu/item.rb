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
    #
    # @example Custom active state logic
    #   Item.new("Dashboard", url: "/dashboard", active: -> (context) {
    #     context.controller.controller_name == "dashboards"
    #   })
    class Item
      # @return [String] The display text for the menu item
      attr_reader :label

      # @return [String, nil] The URL the menu item links to
      attr_reader :url

      # @return [Class, nil] The icon component class to be rendered
      attr_reader :icon

      # @return [String, Component, nil] The badge displayed before the label
      attr_reader :leading_badge

      # @return [Hash] Options for the leading badge
      attr_reader :leading_badge_options

      # @return [String, Component, nil] The badge displayed after the label
      attr_reader :trailing_badge

      # @return [Hash] Options for the trailing badge
      attr_reader :trailing_badge_options

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
        @items = []
        @options = options
        setup_badges(leading_badge, trailing_badge, options)

        yield self if block_given?
      end

      # Creates and adds a nested menu item.
      #
      # @param label [String] The display text for the nested item
      # @param args [Hash] Additional options passed to the Item constructor
      # @yield [item] Optional block for adding further nested items
      # @yieldparam item [Item] The newly created nested item
      # @return [Item] The created nested item
      def item(label, **args, &)
        new_item = self.class.new(label, **args, &)
        @items << new_item
        new_item
      end

      # Add a leading badge to the menu item
      #
      # @param badge [String, Component] The badge content
      # @param opts [Hash] Additional options for the badge
      # @return [self] Returns self for method chaining
      # @raise [ArgumentError] If badge is nil
      def with_leading_badge(badge, **opts)
        raise ArgumentError, "Badge cannot be nil" if badge.nil?

        @leading_badge = badge
        @leading_badge_options = opts.freeze
        self
      end

      # Add a trailing badge to the menu item
      #
      # @param badge [String, Component] The badge content
      # @param opts [Hash] Additional options for the badge
      # @return [self] Returns self for method chaining
      # @raise [ArgumentError] If badge is nil
      def with_trailing_badge(badge, **opts)
        raise ArgumentError, "Badge cannot be nil" if badge.nil?

        @trailing_badge = badge
        @trailing_badge_options = opts.freeze
        self
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
        check_custom_active_state(context) ||
          check_current_page_match(context) ||
          check_nested_items_active(context)
      end

      # Returns a string representation of the menu item.
      #
      # @return [String] A human-readable representation of the menu item
      def inspect
        "#<#{self.class} label=#{@label.inspect} url=#{@url.inspect} items=#{@items.inspect}>"
      end

      private

      # Sets up the badge attributes
      #
      # @param leading_badge [String, Component, nil] The leading badge
      # @param trailing_badge [String, Component, nil] The trailing badge
      # @param options [Hash] Options containing badge configurations
      def setup_badges(leading_badge, trailing_badge, options)
        @leading_badge = leading_badge
        @leading_badge_options = (options.delete(:leading_badge_options) || {}).freeze
        @trailing_badge = trailing_badge
        @trailing_badge_options = (options.delete(:trailing_badge_options) || {}).freeze
      end

      # Checks if there's custom active state logic
      #
      # @param context [Object] The context for active state checking
      # @return [Boolean] Result of custom active check
      def check_custom_active_state(context)
        @options[:active].respond_to?(:call) && @options[:active].call(context)
      end

      # Checks if the current page matches the item's URL
      #
      # @param context [Object] The context for URL matching
      # @return [Boolean] Whether the current page matches
      def check_current_page_match(context)
        context.respond_to?(:helpers) && @url && context.helpers.current_page?(@url)
      end

      # Checks if any nested items are active
      #
      # @param context [Object] The context for checking nested items
      # @return [Boolean] Whether any nested items are active
      def check_nested_items_active(context)
        @items.any? { |item| item.active?(context) }
      end
    end
  end
end
