require "fiber/local"

module Phlexi
  module Menu
    class Theme < Phlexi::Field::Theme
      def self.theme
        @theme ||= {
          nav: nil,
          items_container: nil,
          item_wrapper: nil,
          item_parent: nil,
          item_link: nil,
          item_span: nil,
          item_label: nil,
          leading_badge: nil,
          trailing_badge: nil,
          icon: nil,
          active: nil
        }.freeze
      end
    end
  end
end
