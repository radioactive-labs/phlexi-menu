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
    #           item_label: "text-gray-600"
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
      def initialize(menu, max_depth: DEFAULT_MAX_DEPTH, **options)
        @menu = menu
        @max_depth = max_depth
        @options = options
        super()
      end

      # Renders the menu structure as HTML.
      #
      # @return [String] The rendered HTML
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

        ul(class: themed(:items_container)) do
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
          themed(:item_wrapper),
          active_class(item),
          item_parent_class(item)
        )) do
          render_item_content(item)
          render_items(item.items, depth + 1) if item.items.any?
        end
      end

      # Renders the content of a menu item, choosing between link and span.
      #
      # @param item [Phlexi::Menu::Item] The item to render content for
      def render_item_content(item)
        if item.url
          render_item_link(item)
        else
          render_item_span(item)
        end
      end

      # Renders a menu item as a link.
      #
      # @param item [Phlexi::Menu::Item] The item to render as a link
      def render_item_link(item)
        a(href: item.url, class: themed(:item_link)) do
          render_item_interior(item)
        end
      end

      # Renders a menu item as a span (for non-linking items).
      #
      # @param item [Phlexi::Menu::Item] The item to render as a span
      def render_item_span(item)
        span(class: themed(:item_span)) do
          render_item_interior(item)
        end
      end

      # Renders the interior content of a menu item (badges, icon, label).
      #
      # @param item [Phlexi::Menu::Item] The item to render interior content for
      def render_item_interior(item)
        render_leading_badge(item.leading_badge) if item.leading_badge
        render_icon(item.icon) if item.icon
        render_label(item.label)
        render_trailing_badge(item.trailing_badge) if item.trailing_badge
      end

      # Renders the item's label.
      #
      # @param label [String, Component] The label to render
      def render_label(label)
        phlexi_render(label) {
          span(class: themed(:item_label)) { label }
        }
      end

      # Renders the item's leading badge.
      #
      # @param badge [String, Component] The leading badge to render
      def render_leading_badge(badge)
        phlexi_render(badge) {
          span(class: themed(:leading_badge)) { badge }
        }
      end

      # Renders the item's trailing badge.
      #
      # @param badge [String, Component] The trailing badge to render
      def render_trailing_badge(badge)
        phlexi_render(badge) {
          span(class: themed(:trailing_badge)) { badge }
        }
      end

      # Renders the item's icon.
      #
      # @param icon [Class] The icon component class to render
      def render_icon(icon)
        return unless icon

        div(class: themed(:icon_wrapper)) do
          render icon.new(class: themed(:icon))
        end
      end

      # Determines the active state class for an item.
      #
      # @param item [Phlexi::Menu::Item] The item to check active state for
      # @return [String, nil] The active class name or nil
      def active_class(item)
        item.active?(self) ? themed(:active) : nil
      end

      # Determines the parent state class for an item.
      #
      # @param item [Phlexi::Menu::Item] The item to check parent state for
      # @return [String, nil] The parent class name or nil
      def item_parent_class(item)
        item.items.any? ? themed(:item_parent) : nil
      end

      # Resolves a theme component to its CSS classes.
      #
      # @param component [Symbol] The theme component to resolve
      # @return [String, nil] The resolved CSS classes or nil
      def themed(component)
        self.class::Theme.instance.resolve_theme(component)
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
    end
  end
end
