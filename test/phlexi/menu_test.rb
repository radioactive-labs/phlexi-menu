# frozen_string_literal: true

require "test_helper"

module Phlexi
  class MenuTest < Minitest::Test
    include Capybara::DSL
    include Phlex::Testing::Capybara::ViewHelper

    class TestIcon < Phlex::HTML
      def initialize(**attributes)
        @attributes = attributes
        super()
      end

      def view_template
        div(**@attributes) { "Test Icon" }
      end
    end

    class TestComponent < Phlex::HTML
      def initialize(**attributes)
        @attributes = attributes
        super()
      end

      def view_template
        div(**@attributes) { "Test Component" }
      end
    end

    class TestBadgeComponent < TestComponent
      def initialize(content, **attributes)
        @content = content
        super(**attributes)
      end

      def view_template
        div(**@attributes) { @content }
      end
    end

    class CustomThemeMenu < Phlexi::Menu::Component
      class Theme < Theme
        def self.theme
          super.merge({
            nav: "custom-nav",
            item_label: "custom-label",
            leading_badge_wrapper: "custom-badge-wrapper",
            trailing_badge_wrapper: "custom-badge-wrapper",
            leading_badge: "custom-leading-badge",
            trailing_badge: "custom-trailing-badge"
          })
        end
      end
    end

    class DepthAwareMenu < Phlexi::Menu::Component
      class Theme < Theme
        def self.theme
          super.merge({
            nav: "depth-nav",
            items_container: "depth-items",
            item_wrapper: ->(depth) { ["depth-item", "depth-#{depth}"] },
            item_link: ->(depth) { ["depth-link", depth.zero? ? "root" : "nested"] },
            item_label: ->(depth) { ["depth-label", "level-#{depth}"] },
            icon: ->(depth) { ["depth-icon", depth.zero? ? "primary" : "secondary"] },
            leading_badge_wrapper: ->(depth) { ["badge-wrapper", "indent-#{depth}"] },
            trailing_badge_wrapper: ->(depth) { ["badge-wrapper", "offset-#{depth}"] },
            leading_badge: ->(depth) { ["depth-leading-badge", "indent-#{depth}"] },
            trailing_badge: ->(depth) { ["depth-trailing-badge", "offset-#{depth}"] },
            active: ->(depth) { ["depth-active", "highlight-#{depth}"] }
          })
        end
      end
    end

    # Define a menu component with various types of callable theme values
    class CallableThemeMenu < Phlexi::Menu::Component
      class Theme < Theme
        def self.theme
          super.merge({
            # Lambda returning string
            item_label: ->(depth) { "depth-#{depth}-label" },

            # Lambda returning array
            item_wrapper: ->(depth) { ["wrapper", "level-#{depth}"] },

            # Lambda with conditional logic
            item_link: ->(depth) {
              depth.zero? ? "root-link" : ["nested-link", "indent-#{depth}"]
            },

            # Static string (non-callable)
            nav: "static-nav"
          })
        end
      end
    end

    class TestMenu < Phlexi::Menu::Component
      class Theme < Theme
        def self.theme
          super.merge({
            nav: "test-nav",
            items_container: "test-items",
            item_wrapper: "test-item",
            item_parent: "test-parent",
            item_link: "test-link",
            item_span: "test-span",
            item_label: "test-label",
            leading_badge: "test-leading-badge",
            trailing_badge: "test-trailing-badge",
            icon: "test-icon",
            icon_wrapper: "test-icon-wrapper",
            active: "test-active",
            hover: "test-hover"
          })
        end
      end
    end

    class MockContext
      class MockHelpers
        def initialize(current_page_path)
          @current_page_path = current_page_path
        end

        def current_page?(path)
          path == @current_page_path
        end
      end

      class MockRequest
        attr_reader :path

        def initialize(path)
          @path = path
        end
      end

      attr_reader :request_path, :current_page_path

      def initialize(request_path: "/", current_page_path: "/")
        @request_path = request_path
        @current_page_path = current_page_path
      end

      def request
        @request ||= MockRequest.new(@request_path)
      end

      def helpers
        @helpers ||= MockHelpers.new(@current_page_path)
      end
    end

    def setup
      @menu = Phlexi::Menu::Builder.new do |m|
        m.item("Home",
          url: "/",
          icon: TestIcon,
          leading_badge: "New",
          leading_badge_options: {class: "text-blue-500"},
          trailing_badge: "2",
          trailing_badge_options: {class: "text-sm"})

        m.item "Products", url: "/products" do |products|
          products.item("All Products", url: "/products")
            .with_leading_badge(TestBadgeComponent.new("Featured"), class: "featured")

          products.item "Add Product", url: "/products/new"
        end

        m.item "Settings",
          url: "/settings",
          active: ->(context) { context.respond_to?(:request) && context.request.path.start_with?("/settings") }
      end
    end

    def test_depth_aware_badge_rendering
      deep_menu = Phlexi::Menu::Builder.new do |m|
        m.item("Root")
          .with_leading_badge("L0", class: "l0")
          .with_trailing_badge("T0", class: "t0") do |root|
          root.item("Level 1")
            .with_leading_badge("L1", class: "l1")
            .with_trailing_badge("T1", class: "t1") do |l1|
            l1.item("Level 2")
              .with_leading_badge("L2", class: "l2")
              .with_trailing_badge("T2", class: "t2")
          end
        end
      end

      render DepthAwareMenu.new(deep_menu)

      # Root level (depth 0) assertions
      root_item = ".depth-nav > .depth-items > .depth-item.depth-0"

      # Basic structure assertions
      assert has_css?(root_item)
      assert_equal "depth-item depth-0", find(root_item)[:class]

      # Badge wrappers and content
      assert has_css?("#{root_item} .badge-wrapper.indent-0")
      assert has_css?("#{root_item} .badge-wrapper.offset-0")
      assert has_css?("#{root_item} .badge-wrapper.indent-0 span.l0", text: "L0")
      assert has_css?("#{root_item} .badge-wrapper.offset-0 span.t0", text: "T0")

      # Label assertions
      assert has_css?("#{root_item} span.depth-label.level-0", text: "Root")

      # Verify badge wrapper classes
      wrappers = all("#{root_item} .badge-wrapper", minimum: 0)
      assert_equal 2, wrappers.count
      assert_equal ["badge-wrapper indent-0", "badge-wrapper offset-0"],
        wrappers.map { |w| w[:class] }
    end

    def test_badge_options_mutation
      item = @menu.items.first

      # Initial options shouldn't be nil
      refute_nil item.leading_badge_options
      refute_nil item.trailing_badge_options

      # Original options shouldn't be affected by changes
      original_leading_options = item.leading_badge_options.dup
      original_trailing_options = item.trailing_badge_options.dup

      assert_raises FrozenError do
        item.leading_badge_options[:new_key] = "value"
      end
      assert_raises FrozenError do
        item.trailing_badge_options[:new_key] = "value"
      end

      assert_equal original_leading_options, item.leading_badge_options
      assert_equal original_trailing_options, item.trailing_badge_options
    end

    def test_badge_nil_validation
      assert_raises(ArgumentError) do
        @menu.items.first.with_leading_badge(nil)
      end

      assert_raises(ArgumentError) do
        @menu.items.first.with_trailing_badge(nil)
      end
    end

    # Update existing tests to use the new badge system
    def test_menu_structure
      assert_equal 3, @menu.items.length

      # Test first level items
      home = @menu.items[0]
      assert_equal "Home", home.label
      assert_equal "/", home.url
      assert_equal TestIcon, home.icon
      assert_equal "New", home.leading_badge
      assert_equal "2", home.trailing_badge
      assert_equal({class: "text-blue-500"}, home.leading_badge_options)
      assert_equal({class: "text-sm"}, home.trailing_badge_options)
      assert_empty home.items

      # Test nested items
      products = @menu.items[1]
      assert_equal "Products", products.label
      assert_equal "/products", products.url
      assert_equal 2, products.items.length

      # Test nested item properties
      all_products = products.items[0]
      assert_equal "All Products", all_products.label
      assert_equal "/products", all_products.url
      assert_instance_of TestBadgeComponent, all_products.leading_badge
      assert_equal({class: "featured"}, all_products.leading_badge_options)
    end

    def test_menu_rendering
      render TestMenu.new(@menu)

      # Test basic structure
      assert has_css?(".test-nav")
      assert has_css?(".test-items")

      # Test top-level items count
      assert_equal 3, all(".test-nav > .test-items > .test-item", minimum: 0).count

      # Test Home item structure and content
      home_item = ".test-nav > .test-items > .test-item:first-child"
      assert has_css?("#{home_item} .test-link[href='/']")
      # Fixed badge assertions to match actual structure
      assert has_css?("#{home_item} div span.text-blue-500", text: "New")
      assert has_css?("#{home_item} .test-icon-wrapper .test-icon", text: "Test Icon")
      assert has_css?("#{home_item} .test-label", text: "Home")
      assert has_css?("#{home_item} div span.text-sm", text: "2")

      # Test Products item and its nested structure
      products_item = ".test-nav > .test-items > .test-item:nth-child(2)"
      assert has_css?("#{products_item} .test-link[href='/products']")
      assert has_css?("#{products_item} .test-label", text: "Products")
      assert has_css?("#{products_item}.test-parent")

      # Test nested items under Products
      assert_equal 2, all("#{products_item} > .test-items > .test-item", minimum: 0).count

      # Test All Products item
      all_products = "#{products_item} > .test-items > .test-item:first-child"
      assert has_css?("#{all_products} .test-link[href='/products']")
      # Fixed TestBadgeComponent assertion to match actual structure
      assert has_css?("#{all_products} div div", text: "Featured")
      assert has_css?("#{all_products} .test-label", text: "All Products")

      # Test Add Product item
      add_product = "#{products_item} > .test-items > .test-item:last-child"
      assert has_css?("#{add_product} .test-link[href='/products/new']")
      assert has_css?("#{add_product} .test-label", text: "Add Product")

      # Test Settings item
      settings_item = ".test-nav > .test-items > .test-item:last-child"
      assert has_css?("#{settings_item} .test-link[href='/settings']")
      assert has_css?("#{settings_item} .test-label", text: "Settings")
    end

    def test_active_state_detection
      # Test direct URL match
      mock_context = MockContext.new(
        request_path: "/",
        current_page_path: "/"
      )
      assert @menu.items[0].active?(mock_context), "Home item should be active when current page matches"

      # Test custom active logic
      mock_context = MockContext.new(
        request_path: "/settings/profile",
        current_page_path: "/other"
      )
      assert @menu.items[2].active?(mock_context), "Settings should be active when path starts with /settings"

      # Test parent active state through child URL match
      mock_context = MockContext.new(
        request_path: "/other",
        current_page_path: "/products/new"
      )
      assert @menu.items[1].active?(mock_context), "Products menu should be active when a child URL matches"

      # Test direct child URL match
      mock_context = MockContext.new(
        request_path: "/products",
        current_page_path: "/products"
      )
      assert @menu.items[1].items[0].active?(mock_context), "Child item should be active when its URL matches"

      # Test parent isn't active when URLs don't match
      mock_context = MockContext.new(
        request_path: "/other",
        current_page_path: "/other"
      )
      refute @menu.items[1].active?(mock_context), "Products menu should not be active when no URLs match"
    end

    def test_max_depth_rendering
      deep_menu = Phlexi::Menu::Builder.new do |m|
        m.item "Level 1" do |l1|
          l1.item "Level 2" do |l2|
            l2.item "Level 3" do |l3|
              l3.item "Level 4"
            end
          end
        end
      end

      # Test default max depth (3)
      render TestMenu.new(deep_menu)

      # Check rendered items
      assert has_css?(".test-label", text: "Level 1")
      assert has_css?(".test-label", text: "Level 2")
      assert has_css?(".test-label", text: "Level 3")
      refute has_css?(".test-label", text: "Level 4")

      # Check parent classes
      assert has_css?(".test-item:first-child.test-parent")      # Level 1 should have parent class
      assert has_css?(".test-item .test-item:first-child.test-parent")  # Level 2 should have parent class
      refute has_css?(".test-item .test-item .test-item.test-parent")   # Level 3 shouldn't have parent class

      # Test custom max depth
      render TestMenu.new(deep_menu, max_depth: 2)

      # Check rendered items
      assert has_css?(".test-label", text: "Level 1")
      assert has_css?(".test-label", text: "Level 2")
      refute has_css?(".test-label", text: "Level 3")

      # Check parent classes with custom depth
      assert has_css?(".test-item:first-child.test-parent")     # Level 1 should have parent class
      refute has_css?(".test-item .test-item.test-parent")      # Level 2 shouldn't have parent class
    end

    def test_depth_limited_nesting
      menu = Phlexi::Menu::Builder.new do |m|
        m.item "Root" do |root|
          root.item "Child" do |child|
            child.item "Grandchild" do |grand|
              grand.item "Great-grandchild"
            end
          end
        end
      end

      # Render with max_depth of 2
      render TestMenu.new(menu, max_depth: 2)

      # Check items rendered
      assert has_css?(".test-label", text: "Root")
      assert has_css?(".test-label", text: "Child")
      refute has_css?(".test-label", text: "Grandchild")
      refute has_css?(".test-label", text: "Great-grandchild")

      # Check parent classes based on renderable children
      assert has_css?(".test-item:first-child.test-parent")     # Root should have parent class
      refute has_css?(".test-item .test-item.test-parent")      # Child shouldn't have parent class
    end

    def test_nested_state_with_depth_limit
      menu = Phlexi::Menu::Builder.new do |m|
        m.item "A" do |a|          # depth 0
          a.item "B" do |b|        # depth 1
            b.item "C"             # depth 2
          end
        end
      end

      # Test parent classes at each max_depth
      {
        1 => {
          root: false,     # A can't be nested because depth 1 is max
          child: false     # B won't be rendered at all
        },
        2 => {
          root: true,      # A can be nested because B will be rendered
          child: false     # B can't be nested because depth 2 is max
        },
        3 => {
          root: true,      # A can be nested because B will be rendered
          child: true      # B can be nested because C will be rendered
        }
      }.each do |max_depth, expected|
        component = TestMenu.new(menu, max_depth: max_depth)
        render component

        # Check root level (A)
        if expected[:root]
          assert has_css?("li.test-item.test-parent", text: "A"),
            "At max_depth #{max_depth}, root should have parent class"
        else
          refute has_css?("li.test-item.test-parent", text: "A"),
            "At max_depth #{max_depth}, root should not have parent class"
        end

        # Only check child level (B) if it should be rendered
        if max_depth > 1
          if expected[:child]
            assert has_css?("li.test-item.test-parent li.test-item.test-parent", text: "B"),
              "At max_depth #{max_depth}, child should have parent class"
          else
            refute has_css?("li.test-item.test-parent li.test-item.test-parent", text: "B"),
              "At max_depth #{max_depth}, child should not have parent class"
          end
        end
      end
    end

    def test_component_rendering
      menu = Phlexi::Menu::Builder.new do |m|
        m.item "Item",
          leading_badge: TestComponent.new,
          trailing_badge: TestComponent.new
      end

      # <nav class="test-nav">
      #     <ul class="test-items">
      #         <li class="test-item">
      #             <span class="test-span">
      #                 <div>
      #                     <div>Test Component</div>
      #                 </div>
      #                 <span class="test-label">Item</span>
      #                 <div>
      #                     <div>Test Component</div>
      #                 </div>
      #             </span>
      #         </li>
      #     </ul>
      # </nav>

      actual = TestMenu.new(menu).call
      expected = '<nav class="test-nav"><ul class="test-items"><li class="test-item"><span class="test-span"><div><div>Test Component</div></div><span class="test-label">Item</span><div><div>Test Component</div></div></span></li></ul></nav>'
      assert_equal actual, expected
    end

    def test_theme_customization
      render CustomThemeMenu.new(@menu)

      # Test basic theme customization
      assert has_css?(".custom-nav")

      # Test specific label presence
      assert has_css?(".custom-label", text: "Home")
      assert has_css?(".custom-label", text: "Products")
      assert has_css?(".custom-label", text: "Settings")

      # Test label count
      assert_equal 5, all(".custom-label", minimum: 0).count
    end

    def test_depth_aware_theming
      # Create a deeply nested menu for testing
      deep_menu = Phlexi::Menu::Builder.new do |m|
        m.item "Root",
          url: "/",
          icon: TestIcon,
          leading_badge: "New",
          trailing_badge: "1" do |root|
          root.item "Level 1", url: "/level1" do |l1|
            l1.item "Level 2",
              url: "/level2",
              icon: TestIcon,
              leading_badge: "Beta",
              trailing_badge: "2"
          end
        end
      end

      render DepthAwareMenu.new(deep_menu)

      # Test root level (depth 0) classes
      root = ".depth-nav > .depth-items > li:first-child"
      assert has_css?("#{root}.depth-item.depth-0")
      assert has_css?("#{root} a.depth-link.root")
      assert has_css?("#{root} span.depth-label.level-0", text: "Root")
      assert has_css?("#{root} div.depth-icon.primary", text: "Test Icon")

      # Badge assertions for root level
      assert has_css?("#{root} .badge-wrapper.indent-0 span", text: "New")
      assert has_css?("#{root} .badge-wrapper.offset-0 span", text: "1")

      # Test level 1 classes
      level1 = "#{root} > .depth-items > li:first-child"
      assert has_css?("#{level1}.depth-item.depth-1")
      assert has_css?("#{level1} a.depth-link.nested")
      assert has_css?("#{level1} span.depth-label.level-1", text: "Level 1")

      # Test level 2 classes
      level2 = "#{level1} > .depth-items > li:first-child"
      assert has_css?("#{level2}.depth-item.depth-2")
      assert has_css?("#{level2} a.depth-link.nested")
      assert has_css?("#{level2} span.depth-label.level-2", text: "Level 2")
      assert has_css?("#{level2} div.depth-icon.secondary", text: "Test Icon")

      # Badge assertions for level 2
      assert has_css?("#{level2} .badge-wrapper.indent-2 span", text: "Beta")
      assert has_css?("#{level2} .badge-wrapper.offset-2 span", text: "2")
    end

    def test_depth_aware_active_state
      menu = Phlexi::Menu::Builder.new do |m|
        m.item "Root", url: "/" do |root|
          root.item "Child", url: "/child" do |child|
            child.item "Grandchild", url: "/child/grand"
          end
        end
      end

      # Mock context that considers "/child/grand" as current page
      mock_context = MockContext.new(
        request_path: "/child/grand",
        current_page_path: "/child/grand"
      )

      # Create a component instance with mock context
      component = DepthAwareMenu.new(menu)

      # Add helper methods to allow active state checking
      component.define_singleton_method(:helpers) { mock_context.helpers }
      component.define_singleton_method(:request) { mock_context.request }

      # Render the component
      render component

      # Render with depth-aware theme
      menu_component = DepthAwareMenu.new(menu)
      menu_component.define_singleton_method(:helpers) { mock_context.helpers }
      render menu_component

      # Test active classes at each depth
      assert has_css?(".depth-item.depth-0 .depth-active.highlight-0") # Root
      assert has_css?(".depth-item.depth-1 .depth-active.highlight-1") # Child
      assert has_css?(".depth-item.depth-2 .depth-active.highlight-2") # Grandchild
    end

    def test_callable_theme_values
      menu = Phlexi::Menu::Builder.new do |m|
        m.item "Test", url: "/" do |root|
          root.item "Nested", url: "/nested"
        end
      end

      render CallableThemeMenu.new(menu)

      # Test static theme value
      assert has_css?(".static-nav")

      # Test string-returning lambda
      assert has_css?(".depth-0-label", text: "Test")
      assert has_css?(".depth-1-label", text: "Nested")

      # Test array-returning lambda
      assert has_css?(".wrapper.level-0")
      assert has_css?(".wrapper.level-1")

      # Test conditional lambda
      assert has_css?(".root-link")
      assert has_css?(".nested-link.indent-1")
    end

    def test_badge_initialization
      # Test fluent API
      item = @menu.items.first
      assert_equal "New", item.leading_badge
      assert_equal({class: "text-blue-500"}, item.leading_badge_options)
      assert_equal "2", item.trailing_badge
      assert_equal({class: "text-sm"}, item.trailing_badge_options)

      # Test component badge
      products_item = @menu.items[1].items.first
      assert_instance_of TestBadgeComponent, products_item.leading_badge
      assert_equal({class: "featured"}, products_item.leading_badge_options)
    end

    def test_badge_rendering
      render TestMenu.new(@menu)

      # Test text badges with their options
      assert has_css?("span.text-blue-500", text: "New")
      assert has_css?("span.text-sm", text: "2")

      # Test component badge
      assert has_css?("div", text: "Featured")

      # Test parent structure for badges
      first_item = ".test-nav > .test-items > .test-item:first-child"
      assert has_css?("#{first_item} .test-link div span.text-blue-500")
      assert has_css?("#{first_item} .test-link div span.text-sm")

      products_item = ".test-nav > .test-items > .test-item:nth-child(2)"
      all_products = "#{products_item} > .test-items > .test-item:first-child"
      assert has_css?("#{all_products} .test-link div div", text: "Featured")
    end
  end
end
