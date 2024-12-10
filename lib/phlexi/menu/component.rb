# frozen_string_literal: true

require "phlex"

module Phlexi
  module Menu
    # Base menu component that other menu renderers can inherit from
    class Component < COMPONENT_BASE
      class Theme < Phlexi::Menu::Theme; end

      DEFAULT_MAX_DEPTH = 3

      def initialize(menu, max_depth: DEFAULT_MAX_DEPTH, **options)
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

      # Base implementation handles nesting and delegates individual item rendering
      def render_items(items, depth = 0)
        return if depth >= @max_depth
        return if items.empty?

        ul(class: themed(:items_container)) do
          items.each do |item|
            render_item_wrapper(item, depth)
          end
        end
      end

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

      def render_item_content(item)
        if item.url
          render_item_link(item)
        else
          render_item_span(item)
        end
      end

      def render_item_link(item)
        a(href: item.url, class: themed(:item_link)) do
          render_item_interior(item)
        end
      end

      def render_item_span(item)
        span(class: themed(:item_span)) do
          render_item_interior(item)
        end
      end

      def render_item_interior(item)
        render_leading_badge(item.leading_badge) if item.leading_badge
        render_icon(item.icon) if item.icon
        render_label(item.label)
        render_trailing_badge(item.trailing_badge) if item.trailing_badge
      end

      def render_label(label)
        phlexi_render(label) {
          span(class: themed(:item_label)) { label }
        }
      end

      def render_leading_badge(badge)
        phlexi_render(badge) {
          span(class: themed(:leading_badge)) { badge }
        }
      end

      def render_trailing_badge(badge)
        phlexi_render(badge) {
          span(class: themed(:trailing_badge)) { badge }
        }
      end

      def render_icon(icon)
        return unless icon

        div(class: themed(:icon_wrapper)) do
          render icon.new(class: themed(:icon))
        end
      end

      def active_class(item)
        item.active?(context) ? themed(:active) : nil
      end

      def item_parent_class(item)
        item.items.any? ? themed(:item_parent) : nil
      end

      def themed(component)
        self.class::Theme.instance.resolve_theme(component)
      end

      def phlexi_render(arg, &)
        return unless arg
        raise ArgumentError, "phlexi_render requires a default render block" unless block_given?

        # Handle Phlex components or Rails Renderables
        # if arg.is_a?(Class) && (arg < Phlex::SGML || arg.respond_to?(:render_in))
        #   render arg.new
        # els
        if arg.class < Phlex::SGML || arg.respond_to?(:render_in)
          render arg
        # Handle procs
        elsif arg.respond_to?(:to_proc)
          instance_exec(&arg)
        else
          yield
        end
      end
    end
  end
end
