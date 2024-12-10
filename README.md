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
  - [Component Options](#component-options)
  - [Theming](#theming)
  - [Badge Components](#badge-components)
  - [Rails Integration](#rails-integration)
- [Advanced Usage](#advanced-usage)
  - [Component Customization](#component-customization)
  - [Dynamic Menus](#dynamic-menus)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Features

- Hierarchical menu structure with controlled nesting depth
- Support for icons and dual-badge system (leading and trailing badges)
- Intelligent active state detection
- Flexible theming system
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

# Using the menu
menu = Phlexi::Menu.new do |m|
  m.item "Dashboard", 
    url: "/", 
    icon: DashboardIcon
  
  m.item "Users", 
    url: "/users", 
    leading_badge: "Beta",
    trailing_badge: "23" do |users|
    users.item "All Users", url: "/users"
    users.item "Add User", url: "/users/new"
  end
  
  m.item "Settings", 
    url: "/settings", 
    icon: SettingsIcon,
    leading_badge: CustomBadgeComponent
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

### Component Options

The menu component accepts these initialization options:

```ruby
MainMenu.new(
  menu,                    # The menu instance
  max_depth: 3,           # Maximum nesting depth (default: 3)
  **options               # Additional options passed to templates
)
```

### Theming

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

### Badge Components

Badges can be either strings or Phlex components:

```ruby
class CustomBadgeComponent < ApplicationComponent
  def template
    div(class: "flex items-center") do
      span(class: "h-2 w-2 rounded-full bg-blue-400")
      span(class: "ml-2") { "New" }
    end
  end
end

# Usage
m.item "Products", leading_badge: CustomBadgeComponent
```

### Rails Integration

In your controller:

```ruby
class ApplicationController < ActionController::Base
  def navigation
    @navigation ||= Phlexi::Menu.new do |m|
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
          url: admin_path, 
          leading_badge: "Admin"
      end
    end
  end
  helper_method :navigation
end
```

Note: The menu component uses Rails' `current_page?` helper for default active state detection. If you're not using Rails or want custom active state logic, provide an `active` callable to your menu items:

```ruby
m.item "Custom Active", url: "/path", active: ->(context) {
  # Your custom active state logic here
  context.request.path.start_with?("/path")
}
```

## Advanced Usage

### Component Customization

You can customize specific rendering steps:

```ruby
class CustomMenu < Phlexi::Menu::Component
  # Override just what you need
  def render_item_interior(item)
    div(class: "flex items-center gap-2") do
      render_leading_badge(item.leading_badge) if item.leading_badge
      render_icon(item.icon) if item.icon
      span(class: themed(:item_label)) { item.label.upcase }
      render_trailing_badge(item.trailing_badge) if item.trailing_badge
    end
  end

  def render_leading_badge(badge)
    div(class: tokens(themed(:leading_badge), "flex items-center")) do
      span { "●" }
      span(class: "ml-1") { badge }
    end
  end
end
```

The component provides these customization points:
- `render_items`: Handles collection of items and nesting
- `render_item_wrapper`: Wraps individual items
- `render_item_content`: Chooses between link and span rendering
- `render_item_interior`: Handles the item's internal layout
- `render_leading_badge`: Renders the leading badge
- `render_trailing_badge`: Renders the trailing badge
- `render_icon`: Renders the icon component

### Dynamic Menus

Example of building menus based on user permissions:

```ruby
Phlexi::Menu.new do |m|
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
    m.item org.name, url: organization_path(org), icon: OrgIcon
  end
end
```

## Development

After checking out the repo:

1. Run `bin/setup` to install dependencies
2. Run `bin/appraise install` to install appraisal gemfiles 
3. Run `bin/appraise rake test` to run the tests against all supported versions
4. You can also run `bin/console` for an interactive prompt

For development against a single version, you can just use `rake test`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/radioactive-labs/phlexi-menu.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).