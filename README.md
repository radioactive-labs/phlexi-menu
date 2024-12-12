# Phlexi::Menu

Phlexi::Menu is a flexible and powerful menu builder for Ruby applications. It provides an elegant way to create hierarchical menus with support for icons, badges, and active state detection.

[![Ruby](https://github.com/radioactive-labs/phlexi-menu/actions/workflows/main.yml/badge.svg)](https://github.com/radioactive-labs/phlexi-menu/actions/workflows/main.yml)

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic Usage](#basic-usage)
  - [Menu Items](#menu-items)
  - [Badge System](#badge-system)
  - [Component Options](#component-options)
  - [Nesting and Depth Limits](#nesting-and-depth-limits)
  - [Theming](#theming)
    - [Static Theming](#static-theming)
    - [Depth-Aware Theming](#depth-aware-theming)
  - [Rails Integration](#rails-integration)
- [Advanced Usage](#advanced-usage)
  - [Active State Detection](#active-state-detection)
  - [Component Customization](#component-customization)
    - [Core Rendering Methods](#core-rendering-methods)
    - [Badge Related Methods](#badge-related-methods)
    - [Other Components](#other-components)
    - [Helper Methods](#helper-methods)
  - [Dynamic Menus](#dynamic-menus)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Features

- Hierarchical menu structure with intelligent depth control
- Enhanced badge system with customizable options and wrappers
- Intelligent active state detection
- Flexible theming system with depth awareness
- Smart nesting behavior based on depth limits
- Works seamlessly with Phlex components
- Rails-compatible URL handling
- Customizable rendering components

## Prerequisites

- Ruby >= 3.2.2
- Rails (optional, but recommended)
- Phlex (~> 1.11)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'phlexi-menu'
```

And then execute:

```bash
$ bundle install
```

## Usage

### Basic Usage

```ruby
class MainMenu < Phlexi::Menu::Component
  class Theme < Theme
    def self.theme
      super.merge({
        nav: "bg-white shadow",
        items_container: "space-y-1",
        item_wrapper: ->(depth) { "relative pl-#{depth * 4}" },
        item_link: "flex items-center px-4 py-2 hover:bg-gray-50",
        item_label: ->(depth) { "mx-3 text-gray-#{600 + (depth * 100)}" },
        # Badge wrapper styles
        leading_badge_wrapper: "flex items-center",
        trailing_badge_wrapper: "flex items-center ml-auto",
        # Badge styles
        leading_badge: "mr-2 px-2 py-0.5 text-xs rounded-full bg-blue-100 text-blue-600",
        trailing_badge: "px-2 py-0.5 text-xs rounded-full bg-red-100 text-red-600",
        icon: "h-5 w-5",
        active: "bg-blue-50 text-blue-600"
      })
    end
  end
end

# Using the menu
menu = Phlexi::Menu::Builder.new do |m|
  m.item "Dashboard", url: "/", icon: DashboardIcon
  
  # Using the new fluent badge API
  m.item "Users", url: "/users"
    .with_leading_badge("Beta", color: "blue")
    .with_trailing_badge("23", size: "sm") do |users|
    users.item "All Users", url: "/users"
    users.item "Add User", url: "/users/new"
  end

  m.item "Settings", 
    url: "/settings", 
    icon: SettingsIcon,
    leading_badge: StatusBadge.new(type: "warning")
end

# In your view
render MainMenu.new(menu, max_depth: 2)
```

### Menu Items

Menu items support several options:

```ruby
m.item "Menu Item",
  url: "/path",              # URL for the menu item
  icon: IconComponent,       # Icon component class
  leading_badge: "Beta",     # Leading badge (status/type indicators)
  trailing_badge: "99+",     # Trailing badge (counts/notifications)
  active: ->(context) {      # Custom active state logic
    context.controller_name == "products"
  }
```

The new fluent badge API provides a cleaner way to add badges:

```ruby
m.item "Products"
  .with_leading_badge("New", class: "text-blue-900")
  .with_trailing_badge("99+", class: "text-sm")
```

### Badge System

The enhanced badge system supports both simple text badges and complex component badges with customization options:

```ruby
# Simple text badges with options
m.item "Products"
  .with_leading_badge("New", class: "text-green-400")

# Component badges
m.item "Messages"
  .with_leading_badge(StatusBadge.new(status: "active"))
  .with_trailing_badge(CounterBadge.new(count: 3))

# Legacy style still supported
m.item "Legacy",
  leading_badge: "Beta",
  trailing_badge: "2",
  leading_badge_options: { class: "text-green-400"},
```

### Component Options

The menu component accepts these initialization options:

```ruby
MainMenu.new(
  menu,                   # The menu instance
  max_depth: 3,           # Maximum nesting depth (default: 3)
  **options               # Additional options passed to templates
)
```

### Nesting and Depth Limits

Phlexi::Menu intelligently handles menu nesting based on the specified maximum depth:

```ruby
# Create a deeply nested menu structure
menu = Phlexi::Menu::Builder.new do |m|
  m.item "Level 0" do |l0|        # Will be nested (depth 0)
    l0.item "Level 1" do |l1|     # Will be nested if max_depth > 2
      l1.item "Level 2" do |l2|   # Will be nested if max_depth > 3
        l2.item "Level 3"
      end
    end
  end
end

# Render with depth limit
menu_component = MainMenu.new(menu, max_depth: 2)
```

### Theming

The theming system now includes dedicated wrapper elements for badges:

```ruby
def self.theme
  super.merge({
    # Badge containers
    leading_badge_wrapper: "flex items-center",
    trailing_badge_wrapper: "ml-auto",
    
    # Badge elements
    leading_badge: ->(depth) {
      ["badge", depth.zero? ? "primary" : "secondary"]
    },
    trailing_badge: ->(depth) {
      ["badge", "ml-2", "level-#{depth}"]
    }
  })
end
```

#### Static Theming

Basic theme configuration with fixed classes:

```ruby
class CustomMenu < Phlexi::Menu::Component
  class Theme < Theme
    def self.theme
      super.merge({
        nav: "bg-white shadow rounded-lg",
        items_container: "space-y-1",
        item_wrapper: "relative",
        item_link: "flex items-center px-4 py-2 hover:bg-gray-50",
        item_span: "flex items-center px-4 py-2",
        item_label: "mx-3",
        leading_badge: "mr-2 px-2 py-0.5 text-xs rounded-full bg-blue-100 text-blue-600",
        trailing_badge: "ml-auto px-2 py-0.5 text-xs rounded-full bg-red-100 text-red-600",
        icon: "h-5 w-5",
        active: "bg-blue-50 text-blue-600"
      })
    end
  end
end
```

#### Depth-Aware Theming

Advanced theme configuration with depth-sensitive classes:

```ruby
class DepthAwareMenu < Phlexi::Menu::Component
  class Theme < Theme
    def self.theme
      super.merge({
        item_wrapper: ->(depth) { "relative pl-#{depth * 4}" },
        item_label: ->(depth) { "mx-3 text-gray-#{600 + (depth * 100)}" },
        leading_badge: ->(depth) { 
          ["badge", "mr-2", depth.zero? ? "primary" : "secondary"] 
        }
      })
    end
  end
end
```

Theme values can be either:
- Static strings for consistent styling
- Arrays of classes that will be joined
- Callables (procs/lambdas) that receive the current depth and return strings or arrays

### Rails Integration

In your controller:

```ruby
class ApplicationController < ActionController::Base
  def navigation
    @navigation ||= Phlexi::Menu::Builder.new do |m|
      m.item "Home", 
        url: root_path, 
        icon: HomeIcon
      
      if user_signed_in?
        m.item "Account", 
          url: account_path,
          trailing_badge: notifications_count do |account|
          account.item "Profile", url: profile_path
          account.item "Settings", url: settings_path
          account.item "Logout", url: logout_path
        end
      end

      if current_user&.admin?
        m.item "Admin", 
          url: admin_path
          .with_leading_badge("Admin", variant: "warning")
      end
    end
  end
  helper_method :navigation
end
```

## Advanced Usage

### Active State Detection

The menu system provides multiple ways to determine the active state of items:

```ruby
m.item "Custom Active", 
  url: "/path", 
  active: ->(context) {
    # Custom active state logic
    context.request.path.start_with?("/path")
  }
```

Default behavior checks:
1. Custom active logic (if provided)
2. Current page match
3. Active state of child items

### Component Customization

You can customize specific rendering steps by subclassing the base component and overriding specific methods.

The component provides these customization points:

#### Core Rendering Methods
- `render_items(items, depth)`: Handles collection of items and nesting
- `render_item_wrapper(item, depth)`: Wraps individual items in list elements
- `render_item_content(item, depth)`: Chooses between link and span rendering
- `render_item_interior(item, depth)`: Handles the item's internal layout

#### Badge Related Methods
- `render_leading_badge(item, depth)`: Renders the item's leading badge with wrapper
- `render_trailing_badge(item, depth)`: Renders the item's trailing badge with wrapper
- `render_badge(badge, options, type, depth)`: Core badge rendering with options support

#### Other Components
- `render_icon(icon, depth)`: Renders the icon component
- `render_label(label, depth)`: Renders the item's label

#### Helper Methods
- `nested?(item, depth)`: Determines if an item should show nested children
- `active?(item)`: Determines item's active state
- `active_class(item, depth)`: Resolves active state styling
- `themed(component, depth)`: Resolves theme values for components
- `compute_item_wrapper_classes(item, depth)`: Computes wrapper CSS classes

Each method receives the current depth as a parameter for depth-aware rendering and theming. You can override any combination of these methods to customize the rendering behavior:

```ruby
class CustomMenu < Phlexi::Menu::Component
  # Customize just the badge rendering
  def render_badge(badge, options, type, depth)
    if badge.is_a?(String) && type == :leading_badge
      render_text_badge(badge, options, depth)
    else
      super
    end
  end

  private

  def render_text_badge(text, options, depth)
    span(class: themed(:leading_badge, depth)) do
      span(class: "dot") { "•" }
      text
    end
  end
end
```

For Rails applications, you can also integrate with helpers and routes:

```ruby
class ApplicationMenu < Phlexi::Menu::Component
  protected

  def active?(item)
    return super unless helpers&.respond_to?(:current_page?)
    current_page?(item.url) || item.items.any? { |child| active?(child) }
  end

  def render_icon(icon, depth)
    return super unless icon.respond_to?(:to_svg)
    raw icon.to_svg(class: themed(:icon, depth))
  end
end
```

The component's modular design allows you to customize exactly what you need while maintaining the core menu functionality.

### Dynamic Menus

Example of building menus based on user permissions:

```ruby
Phlexi::Menu::Builder.new do |m|
  # Basic items
  m.item "Home", url: root_path
  
  # Authorization-based items
  if current_user.can?(:manage, :products)
    m.item "Products", url: products_path do |products|
      products.item "All Products", url: products_path
      products.item "Categories", url: categories_path if current_user.can?(:manage, :categories)
      products.item "New Product", url: new_product_path
    end
  end
  
  # Dynamic items from database
  current_user.organizations.each do |org|
    m.item org.name, 
      url: organization_path(org), 
      icon: OrgIcon,
      trailing_badge: org.unread_notifications_count
  end
end
```

## Development

After checking out the repo:

1. Run `bin/setup` to install dependencies
2. Run `bin/appraise install` to install appraisal gemfiles 
3. Run `bin/appraise rake test` to run the tests against all supported versions
4. You can also run `bin/console` for an interactive prompt

For development against a single version, you can just use `bundle exec rake test`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/radioactive-labs/phlexi-menu.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).