require "phlexi-field"

module Phlexi
  module Menu
    class Theme < Phlexi::Field::Theme
      # Defines the default theme structure with nil values
      # Can be overridden in subclasses to provide custom styling
      #
      # @return [Hash] Default theme structure with nil values
      def self.theme
        @theme ||= {
          # Container elements
          nav: nil,                    # Navigation wrapper
          items_container: nil,        # <ul> list container

          # Item structure elements
          item_wrapper: nil,           # <li> item wrapper
          item_parent: nil,            # Additional class for items with visible children
          item_link: nil,              # <a> for clickable items
          item_span: nil,              # <span> for non-clickable items
          item_label: nil,             # Label text wrapper

          # Interactive states
          active: nil,                 # Active/selected state
          hover: nil,                  # Hover state

          # Badge elements
          leading_badge: nil,          # Badge before label
          trailing_badge: nil,         # Badge after label

          # Icon elements
          icon: nil,                   # Icon styling
          icon_wrapper: nil            # Icon container
        }.freeze
      end
    end
  end
end
