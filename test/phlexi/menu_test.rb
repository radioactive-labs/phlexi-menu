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

    class CustomThemeMenu < Phlexi::Menu::Component
      class Theme < Theme
        def self.theme
          super.merge({
            nav: "custom-nav",
            item_label: "custom-label"
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
            active: "test-active"
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
        m.item "Home",
          url: "/",
          icon: TestIcon,
          leading_badge: "New",
          trailing_badge: "2"

        m.item "Products",
          url: "/products" do |products|
          products.item "All Products",
            url: "/products",
            leading_badge: TestComponent.new
          products.item "Add Product",
            url: "/products/new"
        end

        m.item "Settings",
          url: "/settings",
          active: ->(context) { context.respond_to?(:request) && context.request.path.start_with?("/settings") }
      end
    end

    def test_menu_structure
      assert_equal 3, @menu.items.length

      # Test first level items
      home = @menu.items[0]
      assert_equal "Home", home.label
      assert_equal "/", home.url
      assert_equal TestIcon, home.icon
      assert_equal "New", home.leading_badge
      assert_equal "2", home.trailing_badge
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
      # Compare the class of the component instance instead of direct class comparison
      assert_instance_of TestComponent, all_products.leading_badge
    end

    def test_menu_rendering
      render TestMenu.new(@menu)

      # <nav class="test-nav"><ul class="test-items"><li class="test-item"><a href="/" class="test-link"><span class="test-leading-badge">New</span><div><div class="test-icon">Test Icon</div></div><span class="test-label">Home</span><span class="test-trailing-badge">2</span></a></li><li class="test-item test-parent"><a href="/products" class="test-link"><span class="test-label">Products</span></a><ul class="test-items"><li class="test-item"><a href="/products" class="test-link"><div>Test Component</div><span class="test-label">All Products</span></a></li><li class="test-item"><a href="/products/new" class="test-link"><span class="test-label">Add Product</span></a></li></ul></li><li class="test-item"><a href="/settings" class="test-link"><span class="test-label">Settings</span></a></li></ul></nav>

      # Test basic structure
      assert has_css?(".test-nav")
      assert has_css?(".test-items")

      # Test top-level items count
      assert_equal 3, all(".test-nav > .test-items > .test-item", minimum: 0).count

      # Test Home item structure and content
      assert has_css?(".test-nav > .test-items > .test-item:first-child .test-link[href='/']")
      assert has_css?(".test-nav > .test-items > .test-item:first-child .test-leading-badge", text: "New")
      assert has_css?(".test-nav > .test-items > .test-item:first-child .test-icon", text: "Test Icon")
      assert has_css?(".test-nav > .test-items > .test-item:first-child .test-label", text: "Home")
      assert has_css?(".test-nav > .test-items > .test-item:first-child .test-trailing-badge", text: "2")

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
      # Changed to look for the actual rendered component output
      assert has_css?("#{all_products} .test-link div", text: "Test Component")
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

      assert has_css?(".test-label", text: "Level 1")
      assert has_css?(".test-label", text: "Level 2")
      assert has_css?(".test-label", text: "Level 3")
      refute has_css?(".test-label", text: "Level 4")

      # Test custom max depth
      render TestMenu.new(deep_menu, max_depth: 2)

      assert has_css?(".test-label", text: "Level 1")
      assert has_css?(".test-label", text: "Level 2")
      refute has_css?(".test-label", text: "Level 3")
    end

    def test_component_rendering
      menu = Phlexi::Menu::Builder.new do |m|
        m.item "Item",
          leading_badge: TestComponent.new,
          trailing_badge: TestComponent.new
      end

      render TestMenu.new(menu)

      # <nav class="test-nav">
      #   <ul class="test-items">
      #     <li class="test-item">
      #       <span class="test-span">
      #         <div>Test Component</div>
      #         <span class="test-label">Item</span>
      #         <div>Test Component</div>
      #       </span>
      #     </li>
      #   </ul>
      # </nav>

      # Check the number of TestComponent instances
      assert_equal 2, all("div", text: "Test Component", minimum: 0).count

      # Check the label exists with correct text
      assert has_css?(".test-label", text: "Item")
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
  end
end
