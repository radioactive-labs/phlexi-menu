# frozen_string_literal: true

require "phlex"

module Phlexi
  module Menu
    # Base menu component that other menu renderers can inherit from.
    # Provides the core rendering logic for hierarchical menus with support
    # for theming, icons, badges, and active state detection.
    #
    # @example Basic usage
    #   class MyMenu < Phlexi::Menu::Component
    #     class Theme < Theme
    #       def self.theme
    #         super.merge({
    #           nav: "bg-white shadow",
    #           item_label: ->(depth) { "text-gray-#{600 + (depth * 100)}" }
    #         })
    #       end
    #     end
    #   end
    class Component < COMPONENT_BASE
      # Theme class for customizing menu appearance
      class Theme < Phlexi::Menu::Theme; end

      # @return [Integer] The default maximum nesting depth for menu items
      DEFAULT_MAX_DEPTH = 3

      # Initializes a new menu component.
      #
      # @param menu [Phlexi::Menu::Builder] The menu structure to render
      # @param max_depth [Integer] Maximum nesting depth for menu items
      # @param options [Hash] Additional options passed to rendering methods
      def initialize(menu, max_depth: default_max_depth, **options)
        @menu = menu
        @max_depth = max_depth
        @options = options
        super()
      end

      def view_template
        nav(class: themed(:nav)) do
          render_items(@menu.items)
        end
      end

      protected

      # Renders a collection of menu items with nesting support.
      #
      # @param items [Array<Phlexi::Menu::Item>] The items to render
      # @param depth [Integer] Current nesting depth
      def render_items(items, depth = 0)
        return if depth >= @max_depth
        return if items.empty?

        ul(class: themed(:items_container, depth)) do
          items.each do |item|
            render_item_wrapper(item, depth)
          end
        end
      end

      # Renders the wrapper element for a menu item.
      #
      # @param item [Phlexi::Menu::Item] The item to wrap
      # @param depth [Integer] Current nesting depth
      def render_item_wrapper(item, depth)
        li(class: tokens(
          themed(:item_wrapper, depth),
          item_parent_class(item, depth),
          active?(item) ? themed(:active, depth) : nil
        )) do
          render_item_content(item, depth)
          render_items(item.items, depth + 1) if nested?(item, depth)
        end
      end

      def nested?(item, depth)
        has_children = item.items.any?
        within_depth = (depth + 1) < @max_depth
        has_children && within_depth
      end

      def item_parent_class(item, depth)
        nested?(item, depth) ? themed(:item_parent, depth) : nil
      end

      def active?(item)
        item.active?(self)
      end

      # Renders the content of a menu item, choosing between link and span.
      #
      # @param item [Phlexi::Menu::Item] The item to render content for
      # @param depth [Integer] Current nesting depth
      def render_item_content(item, depth)
        if item.url
          render_item_link(item, depth)
        else
          render_item_span(item, depth)
        end
      end

      # Renders a menu item as a link.
      #
      # @param item [Phlexi::Menu::Item] The item to render as a link
      # @param depth [Integer] Current nesting depth
      def render_item_link(item, depth)
        a(
          href: item.url,
          class: tokens(
            themed(:item_link, depth),
            active?(item) ? themed(:active, depth) : nil
          )
        ) do
          render_item_interior(item, depth)
        end
      end

      # Renders a menu item as a span (for non-linking items).
      #
      # @param item [Phlexi::Menu::Item] The item to render as a span
      # @param depth [Integer] Current nesting depth
      def render_item_span(item, depth)
        span(class: themed(:item_span, depth)) do
          render_item_interior(item, depth)
        end
      end

      # Renders the interior content of a menu item (badges, icon, label).
      #
      # @param item [Phlexi::Menu::Item] The item to render interior content for
      # @param depth [Integer] Current nesting depth
      def render_item_interior(item, depth)
        render_leading_badge(item.leading_badge, depth) if item.leading_badge
        render_icon(item.icon, depth) if item.icon
        render_label(item.label, depth)
        render_trailing_badge(item.trailing_badge, depth) if item.trailing_badge
      end

      # Renders the item's label.
      #
      # @param label [String, Component] The label to render
      # @param depth [Integer] Current nesting depth
      def render_label(label, depth)
        phlexi_render(label) {
          span(class: themed(:item_label, depth)) { label }
        }
      end

      # Renders the item's leading badge.
      #
      # @param badge [String, Component] The leading badge to render
      # @param depth [Integer] Current nesting depth
      def render_leading_badge(badge, depth)
        phlexi_render(badge) {
          span(class: themed(:leading_badge, depth)) { badge }
        }
      end

      # Renders the item's trailing badge.
      #
      # @param badge [String, Component] The trailing badge to render
      # @param depth [Integer] Current nesting depth
      def render_trailing_badge(badge, depth)
        phlexi_render(badge) {
          span(class: themed(:trailing_badge, depth)) { badge }
        }
      end

      # Renders the item's icon.
      #
      # @param icon [Class] The icon component class to render
      # @param depth [Integer] Current nesting depth
      def render_icon(icon, depth)
        return unless icon

        div(class: themed(:icon_wrapper, depth)) do
          render icon.new(class: themed(:icon, depth))
        end
      end

      # Determines the active state class for an item.
      #
      # @param item [Phlexi::Menu::Item] The item to check active state for
      # @param depth [Integer] Current nesting depth
      # @return [String, nil] The active class name or nil
      def active_class(item, depth)
        active?(item) ? themed(:active, depth) : nil
      end

      # Helper method to check if an item is active
      #
      # @param item [Phlexi::Menu::Item] The item to check
      # @return [Boolean] Whether the item is active
      def active?(item)
        item.active?(self)
      end

      # Determines if an item should be treated as nested based on its contents
      # and the current depth relative to the maximum allowed depth.
      #
      # @param item [Phlexi::Menu::Item] The item to check
      # @param depth [Integer] Current nesting depth
      # @return [Boolean] Whether the item should be treated as nested
      def nested?(item, depth)
        item.nested? && (depth + 1) < @max_depth
      end

      # Determines the parent state class for an item.
      #
      # @param item [Phlexi::Menu::Item] The item to check parent state for
      # @param depth [Integer] Current nesting depth
      # @return [String, nil] The parent class name or nil
      def item_parent_class(item, depth)
        nested?(item, depth) ? themed(:item_parent, depth) : nil
      end

      # Resolves a theme component to its CSS classes.
      #
      # @param component [Symbol] The theme component to resolve
      # @param depth [Integer] Current nesting depth
      # @return [String, nil] The resolved CSS classes or nil
      def themed(component, depth = 0)
        theme = self.class::Theme.instance.resolve_theme(component)
        return nil if theme.nil?
        return theme unless theme.respond_to?(:call)
        theme.call(depth)
      end

      # Renders either a component or simple value with fallback.
      #
      # @param arg [Object] The value to render
      # @yield The default rendering block
      # @raise [ArgumentError] If no block is provided
      def phlexi_render(arg, &)
        return unless arg
        raise ArgumentError, "phlexi_render requires a default render block" unless block_given?

        if arg.class < Phlex::SGML || arg.respond_to?(:render_in)
          render arg
        elsif arg.respond_to?(:to_proc)
          instance_exec(&arg)
        else
          yield
        end
      end

      def default_max_depth = self.class::DEFAULT_MAX_DEPTH
    end
  end
end
